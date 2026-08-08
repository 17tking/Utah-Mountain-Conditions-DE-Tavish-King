import secrets
import string

# --- Generate a Unique Alphanumeric ID ---
def generate_id(length=24):
    characters = string.ascii_letters + string.digits
    return ''.join(secrets.choice(characters) for _ in range(length))