#  Annuaire Statistique Intelligent du Quartier

> Système numérique de gestion, d'analyse et de valorisation des données démographiques et territoriales

---

##  Démarrage rapide

### 1. Prérequis
- Python 3.9+
- PostgreSQL (base `quartier` déjà créée avec les tables SQL)
- pip

### 2. Installation

```powershell
# Créer un environnement virtuel
python -m venv venv
.\venv\Scripts\Activate.ps1

# Installer les dépendances
pip install -r requirements.txt
```

### 3. Configuration

Copiez `.env.example` en `.env` et renseignez vos paramètres PostgreSQL :

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=quartier
DB_USER=postgres
DB_PASSWORD=votre_mot_de_passe
SECRET_KEY=cle_secrete_unique
```

### 4. Lancer l'application

```powershell
# Option 1 : Script automatique
.\run_dev.ps1

# Option 2 : Manuel
python app.py
```

Accédez à : **http://localhost:5000**

---

##  Identifiants

| Profil | Utilisateur | Mot de passe | Accès |
|--------|-------------|--------------|-------|
|Administrateur | `admin` | `1234` | Tout (CRUD + exports) |
|Agent de collecte | `agent` | `0000` | Saisie & modification |
|Responsable local | `responsable` | `1111` | Consultation + exports |
|hote | `hote` | `2222` | Tableau de bord |

---

##  Structure du projet

```
annuaire_quartier/
├── app.py                  ← Application Flask principale
├── .env                    ← Configuration (DB, clé secrète)
├── .env.example            ← Template de configuration
├── requirements.txt        ← Dépendances Python
├── run_dev.ps1             ← Script de démarrage Windows
├── static/
│   ├── css/style.css       ← Feuille de style complète
│   ├── js/main.js          ← Charts, sidebar, JS utilitaire
│   └── images/             ← Images (background, icônes)
└── templates/
    ├── base.html           ← Layout avec sidebar
    ├── login.html          ← Page de connexion
    ├── dashboard.html      ← Tableau de bord + graphiques
    ├── habitants_*.html    ← Gestion des habitants (CRUD)
    ├── menages_*.html      ← Gestion des ménages (CRUD)
    ├── evenements_*.html   ← Événements vitaux
    ├── mouvements_*.html   ← Mouvements résidentiels
    └── rapports.html       ← Rapports & statistiques
```

---

##  Fonctionnalités

###  Tableau de bord
- KPIs en temps réel (population, ménages, naissances/mois, décès/mois)
- Graphiques : répartition par sexe, pyramide des âges, évolution mensuelle
- Activité récente (derniers événements, derniers habitants)

###  Gestion des habitants
- Enregistrement complet (nom, prénom, sexe, naissance, profession, niveau d'étude, téléphone)
- Recherche multicritère
- Filtrage par sexe et statut
- Rattachement à un ménage
- Fiche détaillée avec historique événements & mouvements

###  Gestion des ménages
- Création avec adresse et revenu estimé
- Vue des membres rattachés
- Statistiques par ménage

###  Événements vitaux
- Naissance, décès
- Mise à jour automatique du statut de l'habitant (décès → "décédé")

###  Mouvements résidentiels
- Arrivées (provenance) et départs (destination)
- Mise à jour automatique du statut (départ → "parti", arrivée → "actif")

###  Rapports & Statistiques
- Indicateurs démographiques (taux natalité, mortalité, solde migratoire)
- Analyse par profession et niveau d'étude
- Évolution mensuelle sur 12 mois
- Barres de progression

###  Exports Excel
- Export habitants (liste complète)
- Rapport complet (habitants + ménages + événements + mouvements + stats)

---

##  Base de données

Tables requises (voir `base_projet_quartier.sql`) :

```sql
Menages          (id_menage, adresse, revenu)
Habitant         (id_habitant, nom, prenom, sexe, date_de_naissance,
                  profession, niveau_etude, telephone, statut, id_menage)
Evenement_vital  (id_evenement, type_evenement, date_evenement,
                  description, id_habitant)
Mouvement_residuel (id_mouvement, type_mouvement, date_mouvement,
                    provenace, destination, id_habitant)
```

---

##  Évolutions futures

- [ ] Authentification avec base de données
- [ ] Export PDF des fiches
- [ ] Cartographie du quartier
- [ ] Alertes démographiques automatiques
- [ ] Application mobile
- [ ] Connexion avec d'autres quartiers (niveau commune)

---

*Projet : Intelligence Territoriale · Gouvernance Locale · Aide à la Décision*
