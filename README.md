# Script Computer Info

Script PowerShell permettant de collecter les informations principales d'une machine Windows locale ou distante et de les enregistrer dans un fichier journal `.log`.

## Informations collectées

Pour chaque collecte, le script enregistre :

- le nom de l'ordinateur et son adresse IP ;
- la version et le numéro de build de Windows ;
- l'espace utilisé et l'espace total de chaque disque local ;
- la mémoire vive utilisée et la mémoire totale ;
- la liste des programmes installés ;
- le nom du processeur.

Les nouvelles collectes sont ajoutées à la fin du fichier log. Les données précédentes ne sont donc pas écrasées.

## Prérequis

- Windows avec PowerShell 5.1 ou une version compatible ;
- une console PowerShell lancée avec les droits administrateur ;
- pour une machine distante : une adresse IP ou un nom d'hôte joignable, des identifiants valides et une administration distante PowerShell configurée ;
- le dossier indiqué pour le fichier log doit déjà exister.

## Syntaxe

```powershell
.\PScript_Tsybulevskyi-Maltsev.ps1 -logPath <chemin-vers-le-fichier.log> [-adresseIP <adresse-ou-nom>]
```

### Paramètres

| Paramètre | Obligatoire | Description |
| --- | --- | --- |
| `-logPath` | Oui | Chemin complet ou relatif du fichier de sortie. Le fichier doit avoir l'extension `.log`. |
| `-adresseIP` | Non | Adresse IP ou nom de la machine distante à interroger. Si le paramètre est omis, la machine locale est utilisée. |

## Utilisation

### Collecte sur la machine locale

Lancer PowerShell en tant qu'administrateur, se placer dans le dossier du script, puis exécuter :

```powershell
.\PScript_Tsybulevskyi-Maltsev.ps1 -logPath "C:\Logs\sysinfo.log"
```

Le fichier `sysinfo.log` est créé automatiquement s'il n'existe pas.

### Collecte sur une machine distante

```powershell
.\PScript_Tsybulevskyi-Maltsev.ps1 -adresseIP "192.168.1.25" -logPath "C:\Logs\sysinfo.log"
```

Le script vérifie d'abord que la machine répond au ping, puis demande les identifiants avec `Get-Credential`. Les informations collectées sur la machine distante sont enregistrées dans le fichier log de la machine locale.

## Exemple de fichier log

```text
----------------------------------
Collecte fait le 2026-03-09 08:14
----------------------------------
2026-03-09 08:14 - DESKTOP-EXAMPLE/192.168.1.10 - Infos système: 10.0.19045 Build 19045 - Disque C: : 120.5 / 237.9 GB - RAM: 7.12 / 16 GB
2026-03-09 08:14 - DESKTOP-EXAMPLE/192.168.1.10 - Programmes installés: Microsoft Edge, Microsoft OneDrive
2026-03-09 08:14 - DESKTOP-EXAMPLE/192.168.1.10 - Info spécifique: 11th Gen Intel(R) Core(TM) i7-11700 @ 2.50GHz
```

## Contrôles et erreurs

Le script s'arrête dans les cas suivants :

- la console PowerShell n'a pas les droits administrateur ;
- `-logPath` n'est pas fourni ;
- le fichier de sortie n'a pas l'extension `.log` ;
- le dossier parent du fichier log n'existe pas ;
- la machine distante ne répond pas au ping ou la connexion PowerShell distante échoue.

## Auteurs

- Tsybulevskyi Maksym
- Maltsev Petro

Date du script : 09.03.2026
