# Configurações
$numeroVersao = Get-Date -Format hhmmssddMMyy
$caminhoArquivo = "NodeGoat-master.zip"
$veracodeAppName = "Teste - SB Fila"

# Lista de SBs
$listaSB = "SB_Dev00", "SB_Dev01", "SB_Dev02", "SB_Dev03", "SB_Dev04", "SB_Dev05", "SB_Dev06", "SB_Dev07", "SB_Dev08"

# Recebe o App ID com base no nome da aplicacao dentro do Veracode
[xml]$INFO = $(.\VeracodeAPI.exe -vid "$veracodeID" -vkey "$veracodeAPIkey" -action GetAppList | Select-String -Pattern $veracodeAppName)
# Filtra o App ID
$VeracodeAppID = $INFO.app.app_id

# Faz o scan na Sandbox selecionada
do {
    foreach ($sbDisponivel in $listaSB) {
        $saidaValidacao = "Nenhuma Sandbox está disponivel"
        try {
            Clear-Host
            Write-Host "Verificando Sandbox $sbDisponivel"
            $retorno = .\VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action UploadAndScan -appname "$veracodeAppName" -createprofile true -sandboxname "$sbDisponivel" -filepath "$caminhoArquivo" -version $numeroVersao
            $validador = $retorno -match "Starting pre-scan verification for application"
            if ($validador -ne "False") {
                $saidaValidacao = "Scan iniciado na Sandbox $sbDisponivel"
                Break
            }
        }
        catch {
            $ErrorMessage = $_.Exception.Message # Recebe o erro
            Write-host "Erro: $ErrorMessage"
        }
    }
    Clear-Host
    Write-Host $saidaValidacao
    Break
} while ($true)