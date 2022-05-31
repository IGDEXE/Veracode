param (
    [parameter(position=0,Mandatory=$True)]
    $nomeProjeto,
    [parameter(position=1,Mandatory=$True)]
    $caminhoPastaProjeto
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

function Install-VeracodeWrapper {
    # Configuracoes
    $urlDownloadAPI = "https://tools.veracode.com/integrations/API-Wrappers/C%23/bin/VeracodeC%23API.zip"
    $pastaInstalacao = "$env:USERPROFILE\.veracode\Tools"

    Clear-Host
    try {
    # Faz o download
        # Verifica se ja tem o PipelineScan
        $existe = Test-Path -Path "$pastaInstalacao/VeracodeAPI.exe"
        if ($Existe -eq $false) {
            Write-Host "Fazendo o download da ferramenta"
            Invoke-WebRequest -Uri "$urlDownloadAPI" -OutFile "$env:LOCALAPPDATA/VeracodeAPI.zip"
            # Descompacta o arquivo
            Write-Host "Descompactando.."
            Expand-Archive -Path "$env:LOCALAPPDATA/VeracodeAPI.zip" -DestinationPath "$pastaInstalacao" -Force
            # Altera o nome do arquivo
            Rename-Item -Path "$pastaInstalacao/VeracodeC#API.exe" -NewName "$pastaInstalacao/VeracodeAPI.exe" -Force
        }
        # Valida se a pasta já não está no Path
        if ($env:Path -match [regex]::escape($pastaInstalacao)) {
            return
        }
        # Adiciona o EXE ao caminho do Path do sistema
        Write-Host "Adicionando ao Path do sistema"
        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pastaInstalacao")
        Write-Host "Procedimento de configuracao concluido" 
    }
    catch {
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        Write-Host "Erro ao fazer a configuracao da API"
        Write-Host "$ErrorMessage"
    }
    
}

# Funcao para validar se o Wrapper esta configurado
function Validar-VeracodeWrapper {
    $validador = Test-Path VeracodeAPI.exe
    if ($validador -eq $false) {
        Install-VeracodeWrapper
    }
}

# Função para executar um SAST
function New-SAST {
    param (
        [parameter(position=0,Mandatory=$True)]
        $AppProfile,
        [parameter(position=1,Mandatory=$True)]
        $caminhoArquivo
    )
    # Valida se o Wrapper esta disponivel
    Validar-VeracodeWrapper
    # Configuracoes
    $numeroVersao = Get-Date -Format hhmmssddMMyy # Cria um hash com base no dia e hora para numero de versão
    # Recebe o valor das credenciais
    $veracodeCredenciais = Get-VeracodeCredentials
    $veracodeID = $veracodeCredenciais[0]
    $veracodeAPIkey = $veracodeCredenciais[1]
    # Faz o scan
    VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action UploadAndScan -appname "$AppProfile" -createprofile true -filepath "$caminhoArquivo" -version $numeroVersao
}

# Faz o zip dos arquivos
Compress-Archive -Path $caminhoPastaProjeto -DestinationPath veracode.zip -Force

# Faz o SAST sem aguardar
New-SAST $nomeProjeto veracode.zip