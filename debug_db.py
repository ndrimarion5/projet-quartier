import os
import sys

# Charger les variables du .env exactement comme dans app.py
import pathlib
env_file = pathlib.Path(__file__).parent / '.env'
if env_file.exists():
    with open(env_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()

# Affiche les valeurs
print("Variables d'environnement chargées:")
print(f"  DB_HOST: {os.environ.get('DB_HOST')}")
print(f"  DB_PORT: {os.environ.get('DB_PORT')}")
print(f"  DB_NAME: {os.environ.get('DB_NAME')}")
print(f"  DB_USER: {os.environ.get('DB_USER')}")
print(f"  DB_PASSWORD: {os.environ.get('DB_PASSWORD')}")

# Test de connexion
import psycopg2
try:
    from urllib.parse import quote
    password_encoded = quote(str(os.environ.get("DB_PASSWORD", "")), safe='')
    dsn = f"postgresql://{os.environ.get('DB_USER')}:{password_encoded}@{os.environ.get('DB_HOST')}:{os.environ.get('DB_PORT')}/{os.environ.get('DB_NAME')}?client_encoding=UTF8"
    
    conn = psycopg2.connect(dsn)
    cur = conn.cursor()
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name")
    tables = cur.fetchall()
    print(f"\nTables trouvées dans {os.environ.get('DB_NAME')}:")
    for table in tables:
        print(f"  - {table[0]}")
    conn.close()
    print("\n Connexion OK!")
except Exception as e:
    print(f"\n Erreur: {e}")
