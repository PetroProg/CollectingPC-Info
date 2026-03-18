<#
.NOTES
    *****************************************************************************
    ETML
    Nom du script : PScript_Tsybulevskyi-Maltsev.ps1 
    Auteur        : Tsybulevskyi Maksym, Maltsev Petro
    Date          : 09.03.2026
    *****************************************************************************
    Modifications
 	Date  : -
 	Auteur: -
 	Raisons: -
 	*****************************************************************************
.SYNOPSIS
    Le script affiche les caractéristiques de la machine locale ou distante.
.DESCRIPTION
    Le script permet de collecter des informations système et de les enregistrer
    dans un fichier log au format "ligne" sans écraser les données précédentes.
.PARAMETER adresseIP
    Cette variable permet de collecter des informations depuis la machine enregistrée à cette adresse IP.
    Ce paramètre est facultatif ; s’il est omis, l’adresse IP de la machine locale sera utilisée.

.PARAMETER logPath
    Dans cette variable, il faudra indiquer le chemin vers le dossier 
    dans lequel les informations obtenues seront enregistrées.

.OUTPUTS
    Le script produit un fichier .log dans le chemin spécifié avec le contenu dedans.

.EXAMPLE
    .\PScript_Tsybulevskyi-Maltsev.ps1 -logPath D:/sysinfolog.log
    Vous avez choisi une Machine Locale

    Consultez le fichier sysloginfo.log pour voir les résultats.

.EXAMPLE
    "Dans le fichier .log"
    ------------
    Collecte fait le 2026-02-23 08:14
    ------------
    2026-02-23 08:14 - DESKTOP-47SMM8M/10.0.2.10 - Infos système: 10.0.19044 Build 19044 - Utilisation de l'éspace disque C: 19.2 GB / 49.4 GB - RAM: 1.16 / 2 GB
    2026-02-23 08:14 - DESKTOP-47SMM8M/10.0.2.10 - Programmes installés: Microsoft Edge, Microsoft Edge WebView2 Runtime, Microsoft OneDrive, Oracle VirtualBox Guest Additions 7.2.6
    2026-02-23 08:14 - DESKTOP-47SMM8M/10.0.2.10 - Info spécifique: 11th Gen Intel(R) Core(TM) i7-11700 @ 2.50GHz

.LINK
    RAS
#>

# La définition des paramètres  
param(
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [string]$adresseIP,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    $logPath
)

###################################################################################################################
# Définition des constantes et variables
Set-Variable -Name ONE -Value 1 -Option Constant

$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$newObj = New-Object System.Security.Principal.WindowsPrincipal($id)
$errorAdmin = New-Object System.UnauthorizedAccessException

###################################################################################################################
# Zone de tests comme les paramètres renseignés ou les droits administrateurs
if (!$newObj.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw $errorAdmin + ("Vous n'avez pas de droits d'administrateur")
    exit
}

# Affiche l'aide si le paramètre logPath n'est pas fourni
# Le script s'arrête après l'affichage de l'aide
if (!$logPath) {
    Get-Help $MyInvocation.Mycommand.Path
    exit
}

# Vérifie que le fichier possède bien l'extension .log
# Si l'extension est différente, une erreur est générée
if ([System.IO.Path]::GetExtension($logPath) -ne ".log") {
    throw "Le fichier doit avoir l'extension .log"
}

# Vérifie que le dossier dans lequel le fichier doit être créé existe
# Si le dossier n'existe pas, le script s'arrête avec une erreur
$directory = Split-Path $logPath -Parent
if (-not (Test-Path $directory)) {
    throw "Le dossier $directory n'existe pas"
}

# Vérifie si le fichier .log existe déjà
# S'il n'existe pas, le script crée automatiquement le fichier
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType File | Out-Null
}

# Vérifie si l'adresse IP n'a pas été fournie en paramètre
# Si elle est vide, la valeur par défaut devient ONE (machine locale)
if (!$adresseIP) {
    $adresseIP = $ONE
}

###################################################################################################################
# Configuration UTF-8 pour toutes les versions de PowerShell à partir de 3.0
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

###################################################################################################################
# Fonction qui collecte différentes informations système de la machine
function Get-SystemInfo {

    # Récupère la date et l'heure actuelles du système
    $datePC = Get-Date -Format "yyyy-MM-dd HH:mm"

    # Récupère le nom de l'ordinateur
    $namePC = (Get-CimInstance CIM_ComputerSystem).Name

    # Récupère les adresses IP actives de la machine
    # Exclut l'adresse de loopback 127.0.0.1
    $ipLocal = (Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'").IPAddress | 
    Where-Object { $_ -like "*.*" -and $_ -ne "127.0.0.1" }
    
    # Récupère la version du système d'exploitation
    $versionOS = (Get-CimInstance -ClassName Win32_OperatingSystem).Version

    # Récupère le numéro de build du système d'exploitation
    $buildOS = (Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber

    # Récupère la liste des disques locaux (DriveType=3)
    # Filtre uniquement les disques ayant une taille supérieure à 0
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3 AND Size > 0"

    # Calcule l'espace utilisé et total pour chaque disque
    $diskResults = foreach ($disk in $disks) {
        [PSCustomObject]@{
            Drive = $disk.DeviceID  # Lettre du disque (ex: C:)
            Used  = [Math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)  # Espace utilisé en GB
            Total = [Math]::Round($disk.Size / 1GB, 2)  # Taille totale du disque en GB
        }
    }

    # Récupère les informations sur la mémoire vive
    $os = Get-CimInstance Win32_OperatingSystem

    # Calcule la RAM utilisée
    $ramUsed = [Math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)

    # Calcule la RAM totale
    $ramTotal = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)

    # Chemins du registre où sont stockées les informations des programmes installés
    $keys = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    # Récupère la liste des programmes installés
    # Supprime les entrées vides et les doublons
    $programs = Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Select-Object -ExpandProperty DisplayName |
    Sort-Object -Unique

    # Récupère le nom du processeur
    $processor = (Get-CimInstance Win32_Processor).Name

    # Crée un objet PowerShell contenant toutes les informations collectées
    # Cet objet sera retourné par la fonction
    [PSCustomObject]@{
        DatePC   = $datePC
        NamePC   = $namePC
        IpLocal  = $ipLocal
        Version  = $versionOS
        Build    = $buildOS
        Disks    = $diskResults   
        RamUsed  = $ramUsed
        RamTot   = $ramTotal
        Programs = ($programs -join ', ')
        CPU      = $processor
    }
}

###################################################################################################################
# MACHINE LOCALE

# Vérifie si l'utilisateur a choisi la machine locale
if ($adresseIP -eq $ONE) {

    # Affiche un message indiquant que la collecte se fait sur la machine locale
    Write-Host "Vous avez choisi une Machine Locale`n"

    # Appelle la fonction qui collecte les informations système
    $resultat = Get-SystemInfo

    # Récupère l'adresse IP de la machine locale
    $ipCible = $resultat.IpLocal

    # Récupère la date et l'heure actuelles pour le journal
    $dateNow = Get-Date -Format "yyyy-MM-dd HH:mm"

    # Formate les informations des disques (lettre du disque, espace utilisé et total)
    $infoDisks = ($resultat.Disks | ForEach-Object {
        "Disque $($_.Drive) : $($_.Used) / $($_.Total) GB"
    }) -join " - "

    # Construit la ligne contenant les informations système générales
    $line1 = "$dateNow - $($resultat.NamePC)/$ipCible - Infos système: $($resultat.Version) Build $($resultat.Build) - $infoDisks - RAM: $($resultat.RamUsed) / $($resultat.RamTot) GB"

    # Construit la ligne contenant la liste des programmes installés
    $line2 = "$dateNow - $($resultat.NamePC)/$ipCible - Programmes installés: $($resultat.Programs)"

    # Construit la ligne contenant une information spécifique (ici le processeur)
    $line3 = "$dateNow - $($resultat.NamePC)/$ipCible - Info spécifique: $($resultat.CPU)"
                                                            
    # Ajoute un séparateur dans le fichier log avec la date de la collecte
    Add-Content -Path $logPath -Value "----------------------------------`nCollecte fait le $dateNow`n----------------------------------"

    # Écrit les différentes informations dans le fichier log
    Add-Content -Path $logPath -Value $line1
    Add-Content -Path $logPath -Value $line2
    Add-Content -Path $logPath -Value $line3

    # Informe l'utilisateur que les résultats sont enregistrés dans le fichier log
    Write-Host "Consultez le fichier .log pour voir les résultats."
}

###################################################################################################################
# MACHINE DISTANTE

# Si l'utilisateur n'a pas choisi la machine locale, le script traite une machine distante
else {

    # Affiche un message indiquant que la collecte se fait sur une machine distante
    Write-Host "Vous avez choisi une Machine Distante`n"

    # Vérifie si la machine distante répond au ping
    $verifIp = Test-Connection -ComputerName $adresseIP -Count 1 -Quiet

    # Si la machine répond au ping
    if ($verifIp) {

        # Demande les identifiants pour se connecter à la machine distante
        $cred = Get-Credential

        # Crée une session PowerShell distante vers la machine cible
        $sess = New-PSSession -ComputerName $adresseIP -Credential $cred -ErrorAction Stop

        # Exécute la fonction Get-SystemInfo sur la machine distante
        $resultat = Invoke-Command -Session $sess -ScriptBlock ${function:Get-SystemInfo}

        # Ferme la session distante
        Remove-PSSession $sess

        # Formate les informations des disques de la machine distante
        $infoDisks = ($resultat.Disks | ForEach-Object {
            "Disque $($_.Drive) $($_.Used) / $($_.Total) GB"
        }) -join " - "

        # Définit l'adresse IP cible comme étant celle de la machine distante
        $ipCible = $adresseIP

        # Récupère la date et l'heure actuelles
        $dateNow = Get-Date -Format "yyyy-MM-dd HH:mm"

        # Construit la ligne contenant les informations système de la machine distante
        $line1 = "$dateNow - $($resultat.NamePC)/$ipCible - Infos système: $($resultat.Version) Build $($resultat.Build) - $infoDisks - RAM: $($resultat.RamUsed) / $($resultat.RamTot) GB"

        # Construit la ligne contenant les programmes installés sur la machine distante
        $line2 = "$dateNow - $($resultat.NamePC)/$ipCible - Programmes installés: $($resultat.Programs)"

        # Construit la ligne contenant l'information spécifique (processeur)
        $line3 = "$dateNow - $($resultat.NamePC)/$ipCible - Info spécifique: $($resultat.CPU)"

        # Ajoute un séparateur avec la date de la collecte dans le fichier log
        Add-Content -Path $logPath -Value "----------------------------------`nCollecte fait le $dateNow`n----------------------------------"

        # Enregistre les informations dans le fichier log local
        Add-Content -Path $logPath -Value $line1
        Add-Content -Path $logPath -Value $line2
        Add-Content -Path $logPath -Value $line3

        # Informe l'utilisateur que les résultats sont disponibles dans le fichier log
        Write-Host "Consultez le fichier .log pour voir les résultats."
    }

    # Si la machine ne répond pas au ping
    else {
        # Affiche un message d'erreur indiquant que l'adresse IP est invalide ou inaccessible
        Write-Error "Adresse IP invalide ou machine inaccessible.`n"
    }
}