#######################################################################################################################
#
#  Remote_Control
#
#######################################################################################################################
#
#  Ce script permet d'exécuter une action sur une Freebox en utilisant les API Freebox
#
#  -------
#   USAGE
#  -------
#
#    1. Installer les certificats "Freebox ECC Root CA.cer" et "Freebox Root CA.cer" sur les machines sur laquelles
#       les scripts vont être exécutés, en tant que certificats racine. Cela va permettre d'utiliser HTTPS au lieu
#       de HTTP qui peut à l'avenir être impossible (source: SDK)
#
#    2. Lancer le script "Autoriser_Remote_Control.ps1" sur l'une des machines du réseau local derrière la Freebox
#       considérée, l'autorisation ne pouvant être délivrée que si l'API a été appelée depuis le LAN (source: SDK),
#       puis suivre les indications affichées.
#
#    3. Une fois le script exécuté avec succès et l'autorisation accordée, copier-coller l'URI de la Freebox et
#       l'identifiant d'application dans le bloc-notes.
#
#    4. Accéder à la Freebox via http://mafreebox.freebox.fr, se connecter, sélectionner "Paramètres de la Freebox",
#       "Gestion des accès", "Applications" et rechercher dans la liste l'application "Remote Control". Cliquer sur
#       "Editer" à droite et modifier les autorisations pour activer "Modification des réglages de la Freebox". Il
#       est possible de désactiver tout le reste qui n'est pas utilisé par l'application.
#
#    5. Faire une copie du fichier "Remote_Control.ps1" et modifier la copie qui peut être renommée, en insérant
#       en ligne 43 l'URI de la Freebox à la place de [Insérer l'URI ici], et en insérant l'identifiant d'application
#       en ligne 46 à la place de [Insérer l'identifiant d'application ici]. Il faut garder les guillemets autour de
#       l'URI et de l'identifiant pour ne pas avoir d'erreur.
#
#    6. Sauver, fermer puis lancer "Remote_Control.ps1" avec un paramètre indiquant l'action à réaliser:
#       ./Remote_Control.ps1 -info ............. Retourne les infos de la box
#       ./Remote_Control.ps1 -reboot ........... Reboote la box
#
#######################################################################################################################



# URI de la Freebox considérée
$AdresseFreebox = "[Insérer l'URI ici]"

# Identifiant de l'application courante
$JetonAppli = "[Insérer l'identifiant d'application ici]"

# Lecture de l'action demandée
if ($args[0] -ieq "-info") {
  $Action = "Infos"
} elseif ($args[0] -ieq "-reboot") {
  $Action = "Reboot"
} else {
  "Paramètre requis manquant ou incorrect."
  Remove-Variable -Name "AdresseFreebox"
  Remove-Variable -Name "JetonAppli"
  exit
}

# Récupération des informations de la Freebox
$FbxApiInfo = Invoke-RestMethod -Uri "$AdresseFreebox/api_version"

# Stocker l'URL de base des appels
$BaseUrl = "$AdresseFreebox$($FbxApiInfo.api_base_url)v$([int]$FbxApiInfo.api_version)"

# Préparer l'ouverture de session
$Challenge = (Invoke-RestMethod -Uri "$BaseUrl/login").result.challenge
$hmacsha = New-Object System.Security.Cryptography.HMACSHA1
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($JetonAppli)
$signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($Challenge))
$password = [string]::join("", ($signature | % {([int]$_).toString('x2')}))
$SessionJson = @"
{
   `"app_id`": `"fr.freebox.remotecontrol`",
   `"password`": `"$($password)`"
}
"@

# Ouvrir la session
$Session = Invoke-RestMethod -Uri "$BaseUrl/login/session/" -Method Post -Body $SessionJson

# Supprimer les variables désormais inutiles
Remove-Variable -Name "JetonAppli"
Remove-Variable -Name "FbxApiInfo"
Remove-Variable -Name "Challenge"
Remove-Variable -Name "hmacsha"
Remove-Variable -Name "signature"
Remove-Variable -Name "password"
Remove-Variable -Name "SessionJson"

if ($Session.success) {
  $JetonSession = $Session.result.session_token;
} else {
  "Echec de l'ouverture de session."
  Remove-Variable -Name "Session"
  Remove-Variable -Name "BaseUrl"
  Remove-Variable -Name "Action"
  Remove-Variable -Name "AdresseFreebox"
  exit
}

# Construire l'entête de session
$EnteteSession = @{'X-Fbx-App-Auth' = $($JetonSession)}
Remove-Variable -Name "JetonSession"

# Exécuter l'action demandée
if ($Action -eq "Infos") {
  $Reponse = Invoke-RestMethod -Uri "$BaseUrl/system/" -Headers $EnteteSession
  ConvertTo-Json $Reponse.result
} elseif ($Action -eq "Reboot") {
  $Reponse = Invoke-RestMethod -Uri "$BaseUrl/system/reboot/" -Method Post -Headers $EnteteSession
  #$Reponse = Invoke-RestMethod -Uri "https://mafreebox.freebox.fr/api/v4/system/reboot/" -Method Post -Headers $EnteteSession
  if ($Reponse.success) {
    "La Freebox est en train de rebooter."
  } else {
    "Reboot de la Freebox impossible: {0}" -f $Reponse.msg
  }
} else {
  $Reponse = "Action inconnue"
  $Reponse
}

# Supprimer les variables restantes
Remove-Variable -Name "Reponse"
Remove-Variable -Name "EnteteSession"
Remove-Variable -Name "Session"
Remove-Variable -Name "BaseUrl"
Remove-Variable -Name "Action"
Remove-Variable -Name "AdresseFreebox"



# EOF