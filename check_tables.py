import psycopg2

conn = psycopg2.connect(
    dbname='bd_quartier',
    user='postgres',
    password='59393620',
    host='localhost'
)

cur = conn.cursor()
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name")
tables = cur.fetchall()
print("Tables dans bd_quartier:")
for table in tables:
    print(f"  - {table[0]}")

if not tables:
    print("  AUCUNE TABLE TROUVÉE!")

conn.close()
