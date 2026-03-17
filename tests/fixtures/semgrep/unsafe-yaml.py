# Tests for unsafe-yaml-load rule
import yaml

# ruleid: unsafe-yaml-load
data = yaml.load(raw)
# ruleid: unsafe-yaml-load
data2 = yaml.load(raw, Loader=yaml.UnsafeLoader)
# ruleid: unsafe-yaml-load
data3 = yaml.load(raw, Loader=yaml.Loader)

# ok: unsafe-yaml-load
data4 = yaml.safe_load(raw)
# ok: unsafe-yaml-load
data5 = yaml.load(raw, Loader=yaml.SafeLoader)
# ok: unsafe-yaml-load
data6 = yaml.load(raw, Loader=yaml.BaseLoader)
