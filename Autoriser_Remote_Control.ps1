#######################################################################################################################
#
#  Autoriser_Remote_Control
#
#######################################################################################################################
#
#  Ce script authentifie le script 'Remote Control' aupr�s de la Freebox sp�cifi�e et r�cup�re
#  l'identifiant d'application correspondant.
#
#######################################################################################################################



# Definition de l'URI de la Freebox locale
$AdresseFreebox = "https://mafreebox.freebox.fr"

# Lecture des infos de version de la Freebox
$FbxApiInfo = Invoke-RestMethod -Uri $AdresseFreebox/api_version

# Stockage de l'URI et du port de la Freebox
if ($FbxApiInfo.https_available) {
  $FreeboxURI = "https://{0}:{1}" -f $FbxApiInfo.api_domain, $FbxApiInfo.https_port
} else {
  $FreeboxURI = "http://{0}" -f $FbxApiInfo.api_domain
}

# D�finir l'application "Reboot Freebox"
$ApplicationInfo = @'
{
  "app_id": "fr.freebox.remotecontrol",
  "app_name": "Remote Control",
  "app_version": "1.0.0",
  "device_name": "demande"
}
'@

# Stocker l'URL de base des appels
$BaseUrl = "$AdresseFreebox$($FbxApiInfo.api_base_url)v$([int]$FbxApiInfo.api_version)"
 
# Demander l'autorisation
$Demande = Invoke-RestMethod -Uri "$BaseUrl/login/authorize" -Method Post -Body $ApplicationInfo
 
# Attente de la r�ponse
$Reponse = Invoke-RestMethod -Uri "$BaseUrl/login/authorize/$($Demande.result.track_id)"
"L'afficheur de la Freebox doit indiquer : ""Autoriser Remote Control sur demande ?"""
"Appuyer sur la fl�che droite de la Freebox pour autoriser."
while ($Reponse.result.status -eq "pending") {
  $Reponse = Invoke-RestMethod -Uri "$BaseUrl/login/authorize/$($Demande.result.track_id)"
  Start-Sleep -Seconds 1
}

# Evaluation de la r�ponse
if ($Reponse.result.status -eq "granted") {
  ""
  "Application ""Remote Control"" autoris�e."
  "URI de la Freebox: {0}" -f $FreeboxURI
  "Identifiant d'application: {0}" -f $Demande.result.app_token
} else {
  ""
  "Echec de l'autorisation: {0}." -f $Reponse.result.status
}

# Suppression des variables
Remove-Variable -Name "AdresseFreebox"
Remove-Variable -Name "FbxApiInfo"
Remove-Variable -Name "FreeboxURI"
Remove-Variable -Name "ApplicationInfo"
Remove-Variable -Name "BaseUrl"
Remove-Variable -Name "Demande"
Remove-Variable -Name "Reponse"

""
Pause

# EOF