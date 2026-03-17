# Tests for no-eval-dynamic-exec-python rule
import ast
import json

# ruleid: no-eval-dynamic-exec-python
result = eval(user_input)
# ruleid: no-eval-dynamic-exec-python
exec(code_string)

# ok: no-eval-dynamic-exec-python
data = json.loads(raw_json)
# ok: no-eval-dynamic-exec-python
value = ast.literal_eval(literal_string)
