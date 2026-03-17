# Tests for fallback-secret-python rule
import os

# ruleid: fallback-secret-python
api_key = os.environ.get("API_KEY", "sk-default-key-12345")
# ruleid: fallback-secret-python
token = os.getenv("AUTH_TOKEN", "default-token")
# ruleid: fallback-secret-python
secret = os.environ.get("SECRET", "fallback-secret")

# ok: fallback-secret-python
host = os.environ.get("DB_HOST", "localhost")
# ok: fallback-secret-python
port = int(os.environ.get("PORT", "8080"))
# ok: fallback-secret-python
env = os.getenv("NODE_ENV", "development")
