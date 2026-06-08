# Lancer l'application en mode développement (Windows PowerShell)
Write-Host "=== Annuaire Statistique du Quartier ===" -ForegroundColor Cyan

# Activer l'environnement virtuel s'il existe
if (Test-Path ".\venv\Scripts\Activate.ps1") {
    Write-Host "Activation de l'environnement virtuel..." -ForegroundColor Yellow
    .\venv\Scripts\Activate.ps1
} else {
    Write-Host "Venv non trouvé. Création en cours..." -ForegroundColor Yellow
    python -m venv venv
    .\venv\Scripts\Activate.ps1
    Write-Host "Installation des dépendances..." -ForegroundColor Yellow
    pip install -r requirements.txt
}

Write-Host "Démarrage du serveur Flask..." -ForegroundColor Green
Write-Host "Accès : http://localhost:5000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Identifiants de connexion :" -ForegroundColor Yellow
Write-Host "  admin / 1234       (Administrateur)" -ForegroundColor White
Write-Host "  agent / 0000       (Agent de collecte)" -ForegroundColor White
Write-Host "  responsable / 1111 (Responsable local)" -ForegroundColor White
Write-Host "  citoyen / 2222     (Citoyen)" -ForegroundColor White
Write-Host ""

python app.py
