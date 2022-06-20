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

function Valida-PipeScan {
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

# Executa o Scan
try {
    # Carrega as credenciais
    $veracodeCredenciais = Get-VeracodeCredentials
    $veracodeID = $veracodeCredenciais[0]
    $veracodeAPIkey = $veracodeCredenciais[1]

    # Valida se a ferramenta está disponivel
    Valida-PipeScan

    # Faz o Scan
    java -jar "pipeline-scan.jar" -vid $veracodeID -vkey $veracodeAPIkey -f $caminhoarquivo
}
catch {
    $ErrorMessage = $_.Exception.Message # Recebe o erro
        Write-Host "Erro ao fazer o scan em: $caminhoarquivo"
        Write-Host "$ErrorMessage"
}