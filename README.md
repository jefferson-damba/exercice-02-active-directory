# Exercice 02 : Infrastructure Active Directory & Automatisation PowerShell

Ce projet présente le déploiement complet et automatisé d'un contrôleur de domaine d'entreprise sous **Windows Server 2022 Standard** virtualisé sur l'hyperviseur Proxmox. L'objectif principal est d'industrialiser la configuration réseau prémissologique, l'installation des services de domaine (AD DS), la création de la forêt cible, ainsi que le provisionnement en masse des groupes de sécurité et des comptes utilisateurs à partir d'un fichier CSV source via un script PowerShell.

---

## 📐 1. Spécifications du Provisioning Appliqué
Le script PowerShell développé a pour mission de lire le fichier de données nommé `utilisateurs.csv` afin d'appliquer les règles de gestion professionnelles suivantes :
* **Nomenclature des comptes (SamAccountName) :** Génération automatique au format normalisé `prenom.nom` en minuscules (ex: `marcelline.alexandre`).
* **Sécurité des authentifications :** Attribution du mot de passe fort global `"Azerty_2025!"` pour l'ensemble des collaborateurs.
* **Cycle de vie des comptes :** Activation immédiate de l'attribut `-ChangePasswordAtLogon $true` obligeant chaque utilisateur à renouveler son mot de passe dès sa première ouverture de session.
* **Gestion multi-groupes :** Analyse dynamique des colonnes de groupes (de 1 à 6). Le script crée le groupe de sécurité Global s'il est absent de l'annuaire, puis y affecte l'utilisateur (permettant la multi-appartenance sans doublon).

---

## 🚀 2. Guide de Déploiement Étape par Étape

### Étape 2.1 : Configuration Réseau Fixe et Nommage du Serveur
Avant toute promotion Active Directory, le serveur doit posséder une identité réseau immuable. Configuration de l'IP fixe en `.100`, de la passerelle en `.2`, du DNS local sur la boucle de retour (`127.0.0.1`), et renommage de la machine en `DC01` via PowerShell Administrateur :

```powershell
$NetAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
New-NetIPAddress -InterfaceAlias $NetAdapter.Name -IPAddress "192.168.221.100" -PrefixLength 24 -DefaultGateway "192.168.221.2"
Set-DnsClientServerAddress -InterfaceAlias $NetAdapter.Name -ServerAddresses "127.0.0.1"
Rename-Computer -NewName "DC01" -Force -Restart

### Étape 2.2 : Déploiement des Services de Domaine AD DS
Installation des binaires du rôle Active Directory et des outils de gestion associés, suivie de la promotion du serveur pour instancier la nouvelle forêt racine nommée laplateforme.io :

```powershell
# 1. Installation du rôle
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# 2. Définition du mot de passe de restauration (DSRM)
$LogonPassword = ConvertTo-SecureString "Azerty_2025!" -AsPlainText -Force

# 3. Promotion en Contrôleur de Domaine
Install-ADDSForest -DomainName "laplateforme.io" -SafeModeAdministratorPassword $LogonPassword -Force

### Étape 2.3 : Intégration du Fichier Source des Employés
Le listing des utilisateurs fourni par l'organisation est encapsulé dans une table structurée CSV et déposé dans le répertoire local sécurisé de l'hôte : `C:\Outils\utilisateurs.csv`.

---

### Étape 2.4 : Exécution du Script d'Automatisation dans l'ISE
Ouverture de l'environnement de script intégré (PowerShell ISE) en mode Administrateur pour exécuter le code d'importation globale et de parsing multi-groupes.

| A. Script de Provisioning chargé dans l'ISE | B. Visualisation des logs de création en console |
| :---: | :---: |
| ![A. Script de Provisioning chargé dans l'ISE](captures/Exécution%du%script%de%peuplement%AD-1.png) | ![B. Visualisation des logs de création en console](captures/Ex%C3%A9cution%20du%20script%20de%20peuplement%20AD-2.png) |

---

## 🧪 3. Phase de Validation et d'Audit du Domaine
Pour valider la conformité de l'exercice, plusieurs vérifications de bas niveau et de haut niveau ont été effectuées sur le contrôleur de domaine.

### A. Audit Visuel via la console dsa.msc
L'ouverture de la console graphique *Utilisateurs et ordinateurs Active Directory* confirme l'injection complète des comptes (Isabelle ARAGON, Marc THILLOT...) ainsi que des groupes de l'entreprise (Animation, Cadres, Technique...) au sein du container structurel **Users** du domaine `laplateforme.io`.

![A. Audit Visuel via la console dsa.msc](captures/Ex%C3%A9cution%20du%20script%20de%20peuplement%20AD-3.png)

### B. Vérification des Imbrications Multi-Groupes
L'analyse des propriétés d'un groupe spécifique (Exemple : groupe *Médical*) atteste de la bonne répartition des employés selon la matrice d'appartenance définie dans le fichier CSV initial.

![B. Vérification des Imbrications Multi-Groupes](captures/Ex%C3%A9cution%20du%20script%20de%20peuplement%20AD-4.png)

### C. Extraction des Objets de l'Annuaire en Ligne de Commande (CLI)
Exécution des requêtes système traditionnelles `net user` et `net group` pour lister à plat les nouveaux objets de sécurité créés sur le serveur de l'infrastructure `\\DC01`.

![C. Extraction des Objets de l'Annuaire en Ligne de Commande (CLI)](captures/Ex%C3%A9cution%20du%20script%20de%20peuplement%20AD-5.png)