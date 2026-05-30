# 1. Définition du chemin local de ton fichier CSV sur le serveur
$csvPath = "C:\Outils\utilisateurs.csv"

# 2. Vérification de l'existence du fichier
if (-not (Test-Path $csvPath)) {
    Write-Error "Le fichier CSV est introuvable à l'adresse : $csvPath"
    return
}

# 3. Importation des données du CSV
$users = Import-Csv -Path $csvPath -Delimiter ","

# 4. Mot de passe générique sécurisé requis
$securePassword = ConvertTo-SecureString "Azerty_2025!" -AsPlainText -Force

Write-Host "--- Début du traitement de l'Active Directory ---" -ForegroundColor Cyan

foreach ($row in $users) {
    # Nettoyage et formatage des noms/prénoms
    $nom = $row.nom.Trim()
    $prenom = $row.prenom.Trim()
    
    # Génération du SamAccountName (ex: marcelline.alexandre)
    $samAccountName = "$($prenom.ToLower()).$($nom.ToLower())"
    $displayName = "$prenom $nom"
    $userPrincipalName = "$samAccountName@laplateforme.io"
    
    # Récupération de tous les groupes de la ligne (groupe1 à groupe6)
    $groupes = @()
    if ($row.groupe1) { $groupes += $row.groupe1.Trim() }
    if ($row.groupe2) { $groupes += $row.groupe2.Trim() }
    if ($row.groupe3) { $groupes += $row.groupe3.Trim() }
    if ($row.groupe4) { $groupes += $row.groupe4.Trim() }
    if ($row.groupe5) { $groupes += $row.groupe5.Trim() }
    if ($row.groupe6) { $groupes += $row.groupe6.Trim() }

    # A. Création des Groupes s'ils n'existent pas
    foreach ($groupe in $groupes) {
        if (-not (Get-ADGroup -Filter "Name -eq '$groupe'")) {
            New-ADGroup -Name $groupe -GroupScope Global -GroupCategory Security -Description "Groupe importé du MiniLab"
            Write-Host "Groupe créé : $groupe" -ForegroundColor Yellow
        }
    }

    # B. Création de l'Utilisateur s'il n'existe pas
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$samAccountName'")) {
        # Création du compte avec mot de passe et obligation de le changer (-ChangePasswordAtLogon $true)
        New-ADUser -SamAccountName $samAccountName `
                   -Name $displayName `
                   -GivenName $prenom `
                   -Surname $nom `
                   -DisplayName $displayName `
                   -UserPrincipalName $userPrincipalName `
                   -AccountPassword $securePassword `
                   -ChangePasswordAtLogon $true `
                   -Enabled $true
                   
        Write-Host "Utilisateur créé : $displayName ($samAccountName)" -ForegroundColor Green
    } else {
        Write-Host "L'utilisateur $samAccountName existe déjà." -ForegroundColor Gray
    }

    # C. Ajout de l'utilisateur dans ses différents groupes
    foreach ($groupe in $groupes) {
        # Vérification si l'utilisateur est déjà membre pour éviter les doublons
        $isMember = Get-ADGroupMember -Identity $groupe | Where-Object {$_.SamAccountName -eq $samAccountName}
        if (-not $isMember) {
            Add-ADGroupMember -Identity $groupe -Members $samAccountName
            Write-Host " -> Ajouté au groupe : $groupe" -ForegroundColor DarkGreen
        }
    }
}

Write-Host "--- Fin du traitement de l'Active Directory ---" -ForegroundColor Cyan