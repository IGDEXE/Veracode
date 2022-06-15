param (
        [parameter(position=0,Mandatory=$True)]
        $caminhoArquivo
)

# Função para pegar as credenciais com base no arquivo de configuração do IDE Scan/Greenlight
function Get-VeracodeCredentials {
    # Pega as credenciais do arquivo da Veracode
    $arquivoCredenciais = Get-Content -Path "C:\Users\$env:UserName\.veracode\credentials"
    # Recebe os valores
    $VeracodeID = $arquivoCredenciais[1].Replace("veracode_api_key_id = ","")
    $APIKey = $arquivoCredenciais[2].Replace("veracode_api_key_secret = ","")
    # Configura a saida
    $veracodeCredenciais = $VeracodeID,$APIKey
    return $veracodeCredenciais
}

# Download e configuração: Pipeline Scan
$urlDownload = "https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip" # Define a url de download
$caminhoDownload = "$env:LOCALAPPDATA/VeracodePipeline.zip" # Define um caminho para o arquivo de download
Invoke-WebRequest -Uri "$urlDownload" -OutFile "$caminhoDownload" # Faz o download
Expand-Archive -Path "$caminhoDownload" -DestinationPath "$pastaferramenta" # Descompacta o ZIP para uma pasta
Remove-Item "$caminhoDownload" # Remove o arquivo de download

# Carrega as credenciais
$veracodeCredenciais = Get-VeracodeCredentials
$veracodeID = $veracodeCredenciais[0]
$veracodeAPIkey = $veracodeCredenciais[1]

# Faz o Scan
java -jar "pipeline-scan.jar" -vid $veracodeID -vkey $veracodeAPIkey -f $caminhoarquivo