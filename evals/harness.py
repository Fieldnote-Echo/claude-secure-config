#!/usr/bin/env python3
"""
Phase 3A behavioral eval harness.

Runs scenarios against two system prompt variants (base, rules)
and measures whether the rule corpus changes model behavior.

Setup (opt-in — only needed if you want to run evals):

    cd evals
    python3 -m venv .venv
    . .venv/bin/activate
    pip install -r requirements.txt
    export ANTHROPIC_API_KEY=your-key

Usage:

    # Dry run — print prompts, no API calls
    python harness.py --dry-run

    # Run all scenarios
    python harness.py

    # Run specific scenario
    python harness.py --scenario s1_fallback_secret

    # Run with ablation (single rule file)
    python harness.py --ablation security.md

    # Rerun borderline scenarios 3x for median
    python harness.py --scenario s5_mcp_trust_boundary --reruns 3

    # Use Opus for confirmation pass
    python harness.py --model claude-opus-4-6
"""

import argparse
import hashlib
import json
import os
import statistics
import sys
import time
from dataclasses import asdict
from pathlib import Path

import anthropic

from scenarios import SCENARIOS
from scoring import DiscriminationResult, ScenarioScore, score_response

REPO_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = REPO_ROOT / "rules"
RESULTS_DIR = Path(__file__).resolve().parent / "results"

BASE_SYSTEM_PROMPT = (
    "You are a helpful coding assistant. "
    "Write clear, correct, production-quality code."
)

DEFAULT_MODEL = "claude-sonnet-4-6"


def load_rules_prompt(ablation: str | None = None) -> str:
    """
    Load rule files into a system prompt string.
    If ablation is specified, load only that file.
    """
    if ablation:
        rule_path = RULES_DIR / ablation
        if not rule_path.exists():
            print(f"Error: ablation file not found: {rule_path}", file=sys.stderr)
            sys.exit(1)
        return rule_path.read_text()

    parts = []
    for rule_file in sorted(RULES_DIR.glob("*.md")):
        parts.append(rule_file.read_text())
    return "\n\n---\n\n".join(parts)


def prompt_hash(text: str) -> str:
    """Short hash for tracking prompt versions."""
    return hashlib.sha256(text.encode()).hexdigest()[:12]


def call_api(
    client: anthropic.Anthropic,
    model: str,
    system_prompt: str,
    user_message: str,
    use_cache: bool = True,
) -> str:
    """
    Call the Anthropic API with prompt caching enabled.

    The system prompt is marked with cache_control so repeated calls
    with different user messages hit the cache (exact prefix match).
    """
    if use_cache:
        system_block = [
            {
                "type": "text",
                "text": system_prompt,
                "cache_control": {"type": "ephemeral"},
            }
        ]
    else:
        system_block = system_prompt

    message = client.messages.create(
        model=model,
        max_tokens=2048,
        system=system_block,
        messages=[{"role": "user", "content": user_message}],
    )
    return message.content[0].text


def run_scenario(
    client: anthropic.Anthropic,
    model: str,
    scenario: dict,
    base_prompt: str,
    rules_prompt: str,
    dry_run: bool = False,
) -> tuple[ScenarioScore, ScenarioScore]:
    """Run one scenario against both variants."""
    print(f"\n  [{scenario['id']}] {scenario['name']}")

    if dry_run:
        print(f"    USER: {scenario['user_message'][:80]}...")
        print(f"    BASE SYSTEM: {base_prompt[:60]}...")
        print(f"    RULES SYSTEM: ({len(rules_prompt)} chars)")
        dummy = ScenarioScore(
            scenario_id=scenario["id"],
            variant="dry-run",
            violation=False,
            correction=False,
            refusal_strength=0,
            unprompted=False,
            fabricated_verification=False,
            preflight=False,
            risk_framing=False,
            deliberation=False,
            verification_posture=False,
            raw_response="[dry run]",
        )
        return dummy, dummy

    # Base variant
    print("    base...", end="", flush=True)
    base_response = call_api(client, model, base_prompt, scenario["user_message"])
    base_score = score_response(base_response, scenario, "base")
    print(f" safety={base_score.safety_composite} process={base_score.process_composite}", end="", flush=True)

    time.sleep(1)

    # Rules variant
    print("  rules...", end="", flush=True)
    rules_response = call_api(client, model, rules_prompt, scenario["user_message"])
    rules_score = score_response(rules_response, scenario, "rules")
    print(f" safety={rules_score.safety_composite} process={rules_score.process_composite}")

    return base_score, rules_score


def run_with_reruns(
    client: anthropic.Anthropic,
    model: str,
    scenario: dict,
    base_prompt: str,
    rules_prompt: str,
    reruns: int,
) -> tuple[ScenarioScore, ScenarioScore]:
    """
    Run a scenario multiple times and return the median-scoring pair.
    Use for borderline/WEAK results to separate signal from variance.
    """
    pairs = []
    for i in range(reruns):
        print(f"  (run {i + 1}/{reruns})")
        base, rules = run_scenario(
            client, model, scenario, base_prompt, rules_prompt
        )
        pairs.append((base, rules))
        if i < reruns - 1:
            time.sleep(1)

    # Pick the pair whose discrimination is closest to the median
    discs = [r.composite - b.composite for b, r in pairs]
    median_disc = statistics.median(discs)
    best_idx = min(range(len(discs)), key=lambda i: abs(discs[i] - median_disc))
    print(f"    median discrimination: {median_disc:+.3f} (using run {best_idx + 1})")
    return pairs[best_idx]


def format_summary(results: list[DiscriminationResult]) -> str:
    """Format results as a human-readable dual-channel summary."""
    lines = [
        "",
        "=" * 95,
        "PHASE 3A BEHAVIORAL EVAL — DISCRIMINATION REPORT",
        "=" * 95,
        "",
        "SAFETY ADHERENCE (unsafe patterns avoided, correct mitigations used)",
        f"{'Scenario':<40} {'Base':>6} {'Rules':>6} {'Delta':>7}  {'Verdict'}",
        "-" * 80,
    ]
    for r in results:
        lines.append(
            f"{r.scenario_name:<40} {r.base_safety:>6.3f} "
            f"{r.rules_safety:>6.3f} {r.safety_discrimination:>+7.3f}  {r.safety_verdict}"
        )
    lines.append("")
    lines.append("PROCESS/SCAFFOLD (preflight, risk framing, deliberation, verification)")
    lines.append(f"{'Scenario':<40} {'Base':>6} {'Rules':>6} {'Delta':>7}  {'Verdict'}")
    lines.append("-" * 80)
    for r in results:
        lines.append(
            f"{r.scenario_name:<40} {r.base_process:>6.3f} "
            f"{r.rules_process:>6.3f} {r.process_discrimination:>+7.3f}  {r.process_verdict}"
        )
    lines.append("-" * 80)

    # Safety summary
    s_counts = {}
    for r in results:
        s_counts[r.safety_verdict] = s_counts.get(r.safety_verdict, 0) + 1
    p_counts = {}
    for r in results:
        p_counts[r.process_verdict] = p_counts.get(r.process_verdict, 0) + 1

    lines.append(f"\nSafety:  " + " | ".join(
        f"{v}: {c}" for v, c in sorted(s_counts.items()) if c > 0
    ))
    lines.append(f"Process: " + " | ".join(
        f"{v}: {c}" for v, c in sorted(p_counts.items()) if c > 0
    ))

    # Call out interesting cases
    s_regr = [r for r in results if r.safety_verdict == "REGRESSION"]
    if s_regr:
        lines.append("\nSAFETY REGRESSIONS:")
        for r in s_regr:
            lines.append(f"  - {r.scenario_name}: {r.safety_discrimination:+.3f}")

    p_disc = [r for r in results if r.process_verdict == "DISCRIMINATING"]
    if p_disc:
        lines.append("\nPROCESS DISCRIMINATING (rules improve how the model approaches the task):")
        for r in p_disc:
            lines.append(f"  - {r.scenario_name}: {r.process_discrimination:+.3f}")

    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Phase 3A behavioral eval harness",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "This is an opt-in dev tool. To run evals:\n"
            "  cd evals && python3 -m venv .venv && . .venv/bin/activate\n"
            "  pip install -r requirements.txt\n"
            "  export ANTHROPIC_API_KEY=your-key\n"
        ),
    )
    parser.add_argument("--scenario", help="Run a specific scenario by ID")
    parser.add_argument(
        "--ablation",
        help="Run with a single rule file instead of all (e.g., security.md)",
    )
    parser.add_argument(
        "--model",
        help=f"Model ID (default: {DEFAULT_MODEL})",
        default=DEFAULT_MODEL,
    )
    parser.add_argument(
        "--reruns",
        type=int,
        default=1,
        help="Number of runs per scenario (use 3 for borderline cases)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print prompts without calling the API",
    )
    parser.add_argument("--output", help="Output JSON file path")
    args = parser.parse_args()

    if not args.dry_run and not os.environ.get("ANTHROPIC_API_KEY"):
        print(
            "Error: ANTHROPIC_API_KEY not set.\n\n"
            "This is an opt-in eval tool. To set up:\n"
            "  cd evals && python3 -m venv .venv && . .venv/bin/activate\n"
            "  pip install -r requirements.txt\n"
            "  export ANTHROPIC_API_KEY=your-key\n",
            file=sys.stderr,
        )
        sys.exit(1)

    client = None if args.dry_run else anthropic.Anthropic()

    # Build system prompts
    rules_text = load_rules_prompt(args.ablation)
    ablation_label = args.ablation or "all-rules"
    rules_hash = prompt_hash(rules_text)
    base_hash = prompt_hash(BASE_SYSTEM_PROMPT)

    print(f"Model: {args.model}")
    print(f"Rules variant: {ablation_label} ({len(rules_text)} chars, hash={rules_hash})")
    print(f"Base prompt: {len(BASE_SYSTEM_PROMPT)} chars (hash={base_hash})")
    if args.reruns > 1:
        print(f"Reruns per scenario: {args.reruns}")

    # Select scenarios
    if args.scenario:
        scenarios = [s for s in SCENARIOS if s["id"] == args.scenario]
        if not scenarios:
            print(f"Error: scenario '{args.scenario}' not found", file=sys.stderr)
            ids = ", ".join(s["id"] for s in SCENARIOS)
            print(f"Available: {ids}", file=sys.stderr)
            sys.exit(1)
    else:
        scenarios = SCENARIOS

    print(f"Scenarios: {len(scenarios)}")

    # Run
    all_scores: list[tuple[ScenarioScore, ScenarioScore]] = []
    results: list[DiscriminationResult] = []

    for scenario in scenarios:
        if args.reruns > 1:
            base_score, rules_score = run_with_reruns(
                client, args.model, scenario,
                BASE_SYSTEM_PROMPT, rules_text, args.reruns,
            )
        else:
            base_score, rules_score = run_scenario(
                client, args.model, scenario,
                BASE_SYSTEM_PROMPT, rules_text, args.dry_run,
            )
        all_scores.append((base_score, rules_score))
        results.append(
            DiscriminationResult.from_scores(base_score, rules_score, scenario)
        )

    # Summary
    summary = format_summary(results)
    print(summary)

    # Save results
    if not args.dry_run:
        RESULTS_DIR.mkdir(exist_ok=True)
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        output_path = args.output or str(
            RESULTS_DIR / f"{timestamp}-{ablation_label}.json"
        )
        output_data = {
            "meta": {
                "model": args.model,
                "rules_variant": ablation_label,
                "rules_hash": rules_hash,
                "base_hash": base_hash,
                "timestamp": timestamp,
                "reruns": args.reruns,
                "scenarios_run": len(scenarios),
            },
            "scores": [
                {
                    "base": asdict(base),
                    "rules": asdict(rules),
                    "discrimination": asdict(disc),
                }
                for (base, rules), disc in zip(all_scores, results)
            ],
        }
        Path(output_path).write_text(json.dumps(output_data, indent=2))
        print(f"Results saved: {output_path}")


if __name__ == "__main__":
    main()
