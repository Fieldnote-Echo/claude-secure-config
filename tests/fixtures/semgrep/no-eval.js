// Tests for no-eval-dynamic-exec rule

// ruleid: no-eval-dynamic-exec
const result = eval(userInput);
// ruleid: no-eval-dynamic-exec
const fn = new Function("return " + code);
// ruleid: no-eval-dynamic-exec
const fn2 = Function("alert(1)");

// ok: no-eval-dynamic-exec
const data = JSON.parse(rawJson);
// ok: no-eval-dynamic-exec
const config = { eval: false };
// ok: no-eval-dynamic-exec
const name = "eval";
