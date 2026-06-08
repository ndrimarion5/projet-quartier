import psycopg2
import bcrypt

# Nouveau mot de passe
new_password = "1901"

# Générer le hash bcrypt
hashed = bcrypt.hashpw(new_password.encode(), bcrypt.gensalt()).decode()

print(f"Ancien mot de passe: 1234")
print(f"Nouveau mot de passe: {new_password}")
print(f"Hash bcrypt: {hashed}")

# Mettre à jour la base de données
conn = psycopg2.connect(
    dbname='bd_quartier',
    user='postgres',
    password='59393620',
    host='localhost'
)

cur = conn.cursor()
cur.execute(
    "UPDATE utilisateurs SET password = %s WHERE username = %s",
    (hashed, 'admin')
)
conn.commit()

print("\n Mot de passe de l'admin mis à jour avec succès!")
print(f"   Nouveau mot de passe: {new_password}")

cur.close()
conn.close()
