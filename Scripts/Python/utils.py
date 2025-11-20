import psycopg2
import os


# -----------------------------------------
# Function to retrieve summit coordinates
# -----------------------------------------
# from utils import get_summits
def get_summits():
    conn = psycopg2.connect(
        dbname=os.getenv('database'),
        user=os.getenv('user'),
        password=os.getenv('password'),
        host=os.getenv('host'),
        port=os.getenv('port')
)
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