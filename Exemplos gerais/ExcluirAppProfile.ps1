# Para utilizar esse projeto, carregue as funcaoes disponiveis no modulo: Windows\Dev Tools\devtools.psm1

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