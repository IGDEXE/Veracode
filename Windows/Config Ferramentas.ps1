# Configuracao
$pastaferramenta  = "$Env:Programfiles/Veracode/" # Define uma pasta onde vamos colocar a ferramenta
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pastaferramenta") # Adiciona o caminho no Path do sistema

# Download e configuração: Pipeline Scan
$urlPipeScan = "https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip" # Define a url de download
Invoke-WebRequest -Uri "$urlDownloadAPI" -OutFile "$env:LOCALAPPDATA/VeracodeAPI.zip" # Faz o download
Expand-Archive -Path "$env:userprofile/Download/pipescan.zip" -DestinationPath "$pastaferramenta" # Descompacta o ZIP para uma pasta

# Download e configuração: API Wrapper
$urlDownloadAPI = "https://tools.veracode.com/integrations/API-Wrappers/C%23/bin/VeracodeC%23API.zip" # Define a url de download
Invoke-WebRequest -Uri "$urlDownloadAPI" -OutFile "$env:LOCALAPPDATA/VeracodeAPI.zip" # Faz o download
Expand-Archive -Path "$env:LOCALAPPDATA/VeracodeAPI.zip" -DestinationPath "$pastaferramenta" # Descompacta o ZIP para uma pasta
Rename-Item -Path "$pastaferramenta/VeracodeC#API.exe" -NewName "$pastaferramenta/VeracodeAPI.exe" # Renomei para remover o # do nome

# Utilizacao das ferrementas:
VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action UploadAndScan -appname "$NomeApp" -filepath "$caminhoArquivo" -version $numeroVersao # API Wrapper
java -jar "pipeline-scan.jar" -vid $veracodeID -vkey $veracodeAPIkey -f $caminhoarquivo # Pipeline Scan