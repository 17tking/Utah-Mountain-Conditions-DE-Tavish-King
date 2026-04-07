import psycopg2
import os
import time
import requests
from dotenv import load_dotenv

load_dotenv()


def _get_conn():
    """Internal helper to open a DB connection."""
    return psycopg2.connect(
        dbname=os.getenv('database'),
        user=os.getenv('user'),
        password=os.getenv('password'),
        host=os.getenv('host'),
        port=os.getenv('port')
    )


# -----------------------------------------
# Function to retrieve summit coordinates
# -----------------------------------------
# from utils import get_summits
def get_summits():
    conn = _get_conn()
    cur = conn.cursor()

    query = """
        select mtn_id, latitude, longitude
        from bronze.wiki_mtns
        where latitude is not null
            and longitude is not null
    """

    cur.execute(query)
    rows = cur.fetchall()

    cur.close()
    conn.close()

    return [
        {"mtn_id": r[0], "latitude": float(r[1]), "longitude": float(r[2])}
        for r in rows
    ]


# -----------------------------------------
# Retry Logic
# -----------------------------------------
def call_api_with_retry(url, params, retries=3, backoff=60):
    for attempt in range(retries):
        r = requests.get(url, params=params, timeout=10)
        if r.status_code == 200:
            return r
        elif r.status_code == 429:
            if attempt < retries - 1:
                print(f"Rate limited (429). Waiting {backoff}s before retry {attempt + 1}/{retries - 1}...")
                time.sleep(backoff)
            else:
                print(f"Rate limited (429). No retries left.")
                return r
        else:
            return r
    return r


# -----------------------------------------
# API call logger
# -----------------------------------------
# Logs each API call to bronze.api_call_log.
#
# Usage — wrap your requests.get() like this:
#
#   from utils import log_api_call
#   import time
#
#   start = time.time()
#   r = requests.get(url, params=params, timeout=10)
#   log_api_call(
#       api_source='openmeteo',
#       endpoint=url,
#       mtn_id=s['mtn_id'],
#       status_code=r.status_code,
#       response_ms=round((time.time() - start) * 1000),
#       success=r.status_code == 200
#   )
#
# On API failure (exception before a response), pass:
#   status_code=None, success=False, error_message=str(e)
# -----------------------------------------
def log_api_call(
    api_source,
    endpoint,
    mtn_id=None,
    status_code=None,
    response_ms=None,
    success=True,
    error_message=None
):
    try:
        conn = _get_conn()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO bronze.api_call_log (
                api_source,
                endpoint,
                mtn_id,
                status_code,
                response_ms,
                success,
                error_message
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (api_source, endpoint, mtn_id, status_code, response_ms, success, error_message))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        # Logging should never crash the pipeline — fail silently here
        print(f"Warning: api_call_log insert failed: {e}")