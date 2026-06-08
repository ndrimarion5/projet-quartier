import psycopg2

conn = psycopg2.connect(
    dbname='bd_quartier',
    user='postgres',
    password='59393620',
    host='localhost'
)

cur = conn.cursor()
cur.execute("SELECT username, label, role FROM utilisateurs ORDER BY role")
print("\n=== Comptes disponibles ===\n")
for row in cur.fetchall():
    print(f"  Username: {row[0]}")
    print(f"  Label:    {row[1]}")
    print(f"  Rôle:     {row[2]}")
    print()

conn.close()
