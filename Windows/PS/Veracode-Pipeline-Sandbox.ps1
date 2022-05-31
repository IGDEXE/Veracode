param (
    [parameter(position=0,Mandatory=$True)]
    $nomeProjeto,
    [parameter(position=1,Mandatory=$True)]
    $caminhoPastaProjeto,
    [parameter(position=2,Mandatory=$True)]
    $siglaAmbiente
)

# Funcoes para facilitar processos
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

# Função para executar um SAST
function New-SAST {
    param (
        [parameter(position=0,Mandatory=$True)]
        $AppProfile,
        [parameter(position=1,Mandatory=$True)]
        $caminhoArquivo,
        [parameter(position=2,Mandatory=$True)]
        $siglaAmbiente
    )
    # Configuracoes
    $numeroVersao = Get-Date -Format hhmmssddMMyy # Cria um hash com base no dia e hora para numero de versão
    # Recebe o valor das credenciais
    $veracodeCredenciais = Get-VeracodeCredentials
    $veracodeID = $veracodeCredenciais[0]
    $veracodeAPIkey = $veracodeCredenciais[1]
    # Faz o scan
    VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action UploadAndScan -appname "$AppProfile" -createprofile true -sandboxname "$siglaAmbiente" -createsandbox true  -filepath "$caminhoArquivo" -version $numeroVersao
}

# Faz o zip dos arquivos
Compress-Archive -Path $caminhoPastaProjeto -DestinationPath veracode.zip -Force

# Faz o SAST sem aguardar
New-SAST $nomeProjeto veracode.zip $siglaAmbiente