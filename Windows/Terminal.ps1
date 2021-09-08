# SCA
iex ((New-Object System.Net.WebClient).DownloadString('https://download.srcclr.com/ci.ps1')) # Faz o download do script
srcclr scan --ws=D77HraA # Executa o scan


# Pipeline Scan
# Download e configuracao
$pastaferramenta  = "$Env:Programfiles/Veracode/PipelineScan" # Define uma pasta onde vamos colocar a ferramenta
$urlPipeScan = "https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip" # Define a url de download
Invoke-WebRequest -Uri "$urlDownloadAPI" -OutFile "$env:LOCALAPPDATA/VeracodeAPI.zip" # Faz o download
Expand-Archive -Path "$env:userprofile/Download/pipescan.zip" -DestinationPath "$pastaferramenta" # Descompacta o ZIP para uma pasta
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pastaferramenta") # Adiciona o caminho no Path do sistema
# Utilizacao
java -jar "pipeline-scan.jar" -vid $veracodeID -vkey $veracodeAPIkey -f $caminhoarquivo 


# API Wrapper
# Download e configuracao
$pastaferramenta  = "$Env:Programfiles/Veracode/API/.NET" # Define uma pasta onde vamos colocar a ferramenta
$urlDownloadAPI = "https://tools.veracode.com/integrations/API-Wrappers/C%23/bin/VeracodeC%23API.zip" # Define a url de download
Invoke-WebRequest -Uri "$urlDownloadAPI" -OutFile "$env:LOCALAPPDATA/VeracodeAPI.zip" # Faz o download
Expand-Archive -Path "$env:LOCALAPPDATA/VeracodeAPI.zip" -DestinationPath "$pastaferramenta" # Descompacta o ZIP para uma pasta
Rename-Item -Path "$pastaferramenta/VeracodeC#API.exe" -NewName "$pastaferramenta/VeracodeAPI.exe" # Renomei para remover o # do nome
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pastaferramenta") # Adiciona o caminho no Path do sistema
# Utilizacao
$numeroVersao = Get-Date -Format hhmmssddMMyy # Cria um hash com base no dia e hora para numero de versão
VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action UploadAndScan -appname "$NomeApp" -filepath "$caminhoArquivo" -version $numeroVersao