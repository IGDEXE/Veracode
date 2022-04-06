# Função para criar novas credenciais
function New-VeracodeCredentials {
    param (
        [parameter(position=0,Mandatory=$True)]
        $veracodeID,
        [parameter(position=1,Mandatory=$True)]
        $veracodeAPIkey
    )
    # Valida se a pasta da Veracode existe
    $pastaferramenta = "$env:USERPROFILE\.veracode\"
    $existe = Test-Path -Path "$pastaferramenta"
    if ($Existe -eq $false) {
        # Cria a pasta
        New-Item -ItemType "directory" -Path "$pastaferramenta"
    }
    # Faz a criação do arquivo
    $caminhoArquivo = "$pastaferramenta\credentials"
    $arquivoCredenciais = "[default]","veracode_api_key_id = $veracodeID","veracode_api_key_secret = $veracodeAPIkey"
    Add-Content -Path $caminhoArquivo -Value $arquivoCredenciais
}

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
function Install-PipeScan {
    # Pasta padrao
    $pastaferramenta  = "$Env:Programfiles/Veracode/PipeScan"
    # Instalador
    $caminhoInstalador = "$env:userprofile/Download/pipescan.zip"
    # Link para fazer o download da ferramenta, conforme documentação
    $urlPipeScan = "https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip" # Link para fazer o download da ferramenta, conforme documentação

    # Instalacao da ferramenta
    try {
        # Verifica se ja tem o PipelineScan
        $existe = Test-Path -Path "$pastaferramenta"
        if ($Existe -eq $false) {
            # Faz o download
            Invoke-WebRequest -Uri "$urlPipeScan" -OutFile "$caminhoInstalador"
            # Extrai o arquivo
            Expand-Archive -Path "$caminhoInstalador" -DestinationPath "$pastaferramenta"
            # Adiciona o EXE ao caminho do Path do sistema
            Write-Host "Adicionando ao Path do sistema"
            [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pastaferramenta")
        }
        # Caso ela ja esteja instalada, nada é feito
    }
    catch {
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        Write-Host "Erro ao fazer o download do Pipeline Scan"
        Write-Host "$ErrorMessage"
    }
}

# Função para utilização do Pipeline Scan
function New-PipelineScan {
    # Define os parametros que serao utilizados
    param (
        [parameter(position=0,Mandatory=$True)]
        $arquivo
    )
    try {
        # Verifica se a ferramenta já esta instalada, se não faz a instalação
        Install-PipeScan
        # Recebe o valor das credenciais
        $veracodeCredenciais = Get-VeracodeCredentials
        $veracodeID = $veracodeCredenciais[0]
        $veracodeAPIkey = $veracodeCredenciais[1]
        # Filtra os objetos
        $nomearquivo = $arquivo.name # Recebe o nome do arquivo, exemplo: Foto123.png
        $caminhoarquivo = $arquivo.fullname # Recebe o caminho do arquivo: C:/Fotos/Foto123.png
        # Scan
        java -jar "pipeline-scan.jar" -vid $veracodeID -vkey $veracodeAPIkey -f $caminhoarquivo # Faz a validação conforme as orientações do fabricante
    }
    catch {
        # Esse bloco é ativado no caso de algum problema ocorrer no uso dos comandos anteriores
        # Recebendo o erro e exibindo ele, parando a execução
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        # Mostra uma mensagem personalizada
        Write-Host "Erro ao verificar o arquivo: $nomearquivo"
        Write-Host "$ErrorMessage"
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
    # Configuracoes
    $numeroVersao = Get-Date -Format hhmmssddMMyy # Cria um hash com base no dia e hora para numero de versão
    # Recebe o valor das credenciais
    $veracodeCredenciais = Get-VeracodeCredentials
    $veracodeID = $veracodeCredenciais[0]
    $veracodeAPIkey = $veracodeCredenciais[1]
    # Faz o scan
    VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action UploadAndScan -appname "$AppProfile" -filepath "$caminhoArquivo" -version $numeroVersao
}

# Instalar Veracode Wrapper
function Install-VeracodeWrapper {
    # Configuracoes
    $urlDownloadAPI = "https://tools.veracode.com/integrations/API-Wrappers/C%23/bin/VeracodeC%23API.zip"
    $pastaInstalacao = "$env:USERPROFILE\.veracode\Tools"

    Clear-Host
    try {
    # Faz o download
        Write-Host "Fazendo o download da ferramenta"
        Invoke-WebRequest -Uri "$urlDownloadAPI" -OutFile "$env:LOCALAPPDATA/VeracodeAPI.zip"
        # Descompacta o arquivo
        Write-Host "Descompactando.."
        Expand-Archive -Path "$env:LOCALAPPDATA/VeracodeAPI.zip" -DestinationPath "$pastaInstalacao" -Force
        # Altera o nome do arquivo
        Rename-Item -Path "$pastaInstalacao/VeracodeC#API.exe" -NewName "$pastaInstalacao/VeracodeAPI.exe"
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
    if ($validador -eq "False") {
        Install-VeracodeWrapper
    }
}

# Funcao para excluir App Profiles
function Delete-VeracodeAppProfile {
    param (
        $appName
    )
    
    # Recebe as credenciais
    $veracodeCredenciais = Get-VeracodeCredentials
    $veracodeID = $veracodeCredenciais[0]
    $veracodeAPIkey = $veracodeCredenciais[1]

    # Valida se Wrapper ja esta configurado
    Validar-VeracodeWrapper

    try {
        # Recebe o App ID com base no nome da aplicacao dentro do Veracode
        [xml]$INFO = $(VeracodeAPI.exe -vid "$veracodeID" -vkey "$veracodeAPIkey" -action GetAppList | Select-String -Pattern $appName)
        # Filtra o App ID
        $appID = $INFO.app.app_id

        # Remove o perfil informado
        Write-Host "Removendo perfil: $appName"
        [xml]$Status = VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action deleteapp -appid "$appID"

        # Faz a validacao
        $resultado = $status.deleteapp.result
        if ($resultado -eq "success") {
            Write-Host "O perfil $appName foi removido com sucesso"
        } else {
            Write-Host "Erro ao deletar o perfil: $appName"
            Write-Host $Status
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        Write-Host "Erro ao deletar o perfil: $appName"
        Write-Host "$ErrorMessage"
    }
}

# Funcao para listar todos os Apps
function Get-AllVeracodeProfiles {
    # Recebe as credenciais
    $veracodeCredenciais = Get-VeracodeCredentials
    $veracodeID = $veracodeCredenciais[0]
    $veracodeAPIkey = $veracodeCredenciais[1]

    # Valida se Wrapper ja esta configurado
    Validar-VeracodeWrapper

    # Recebe o XML dos perfis
    [xml]$INFO = $(VeracodeAPI.exe -vid "$veracodeID" -vkey "$veracodeAPIkey" -action getapplist)

    # Filtra os nomes dos perfis
    $nomesAppProfile = $INFO.applist.app.app_name

    # Retorna a lista de perfis
    return $nomesAppProfile
}