# Lembrar de sempre executar o script como administrador
# Caso não queira fazer isso, execute as funções de validação assim para a correta configuração das ferramentas

# Configuracoes gerais
$AppProfile = "TestePS - NodeGoat"
$caminhoArquivo = "$env:userprofile\Download\NodeGoat-JS-main.zip"
#$pastaProjeto = "Definir apenas se o script for executado fora da pasta base do projeto/ colocar o caminho da pasta raiz"


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

# Instalar Pipeline Scan
function Validar-PipeScan {
    # Pasta padrao
    $pastaferramenta  = "$env:USERPROFILE\.veracode\Tools\PipeScan"
    # Instalador
    $caminhoInstalador = "$env:LOCALAPPDATA/pipescan.zip"
    # Link para fazer o download da ferramenta, conforme documentação
    $urlPipeScan = "https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip" # Link para fazer o download da ferramenta, conforme documentação

    # Instalacao da ferramenta
    try {
        # Verifica se ja tem o PipelineScan
        $existe = Test-Path -Path "$pastaferramenta"
        if ($Existe -eq $false) {
            # Faz o download
            Invoke-WebRequest -Uri "$urlPipeScan" -OutFile "$caminhoInstalador"
            # Cria a pasta
            New-Item -ItemType "directory" -Path "$pastaferramenta"
            # Extrai o arquivo
            Expand-Archive -Path "$caminhoInstalador" -DestinationPath "$pastaferramenta" -Force
        }
        # Valida se a pasta já não está no Path
        if ($env:Path -match [regex]::escape($pastaferramenta)) {
            return
        }
        # Adiciona o EXE ao caminho do Path do sistema
        Write-Host "Adicionando ao Path do sistema"
        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pastaferramenta")
        # Caso ela ja esteja instalada, nada é feito
    }
    catch {
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        Write-Host "Erro ao fazer o download do Pipeline Scan"
        Write-Host "$ErrorMessage"
    }
}

# Instalar Veracode Wrapper
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

# Função para utilização do Pipeline Scan
function New-PipelineScan {
    # Define os parametros que serao utilizados
    param (
        [parameter(position=0,Mandatory=$True)]
        $caminhoarquivo
    )
    try {
        # Verifica se a ferramenta já esta instalada, se não faz a instalação
        Validar-PipeScan
        # Recebe o valor das credenciais
        $veracodeCredenciais = Get-VeracodeCredentials
        $veracodeID = $veracodeCredenciais[0]
        $veracodeAPIkey = $veracodeCredenciais[1]
        # Scan
        java -jar "pipeline-scan.jar" -vid $veracodeID -vkey $veracodeAPIkey -f $caminhoarquivo --issue_details true # Faz a validação conforme as orientações do fabricante
    }
    catch {
        # Recebendo o erro e exibindo ele, parando a execução
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        # Mostra uma mensagem personalizada
        Write-Host "$ErrorMessage"
    }
}

# Funcao para o SCA
function New-SCA {
    param (
        $pastaProjeto
    )

    # Valida se foi passado algum parametro
    if ($pastaProjeto -eq "") {
        Set-Location $pastaProjeto
    }

    # Valida se a variavel de ambiente existe
    if ($Env:SRCCLR_API_TOKEN -eq $null) {
        Write-Host "Não foi possivel fazer o scan"
        Write-Host "A variavel de ambiente SRCCLR_API_TOKEN não foi configurada"
        break
    }

    # Faz o download do script
    iex ((New-Object System.Net.WebClient).DownloadString('https://download.srcclr.com/ci.ps1'))

    # Faz o scan
    srcclr scan --update-advisor --pull-request --allow-dirty
}

# Pipeline seguindo o fluxo: SAST sem aguardar -> SCA -> Pipeline Scan
Clear-Host
# Faz o SAST sem aguardar
New-SAST $AppProfile $caminhoArquivo

# Faz o SCA
New-SCA

# Faz o Pipeline Scan
New-PipelineScan $caminhoArquivo