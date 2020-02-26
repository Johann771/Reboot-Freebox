#######################################################################################################################
#
#  Adresse Freebox locale
#
#######################################################################################################################
#
#  Ce script retourne l'adresse de la Freebox locale, pour une utilisation distante d'autres scripts
#
#######################################################################################################################



# Lecture des infos de version de la Freebox
$FbxApiInfo = Invoke-RestMethod -Uri "http://mafreebox.freebox.fr/api_version"

# Extraction et affichage des informations
if ($FbxApiInfo.https_available) {
  "https://{0}:{1}" -f $FbxApiInfo.api_domain, $FbxApiInfo.https_port
} else {
  "http://{0}" -f $FbxApiInfo.api_domain
}

""
Pause
# EOF