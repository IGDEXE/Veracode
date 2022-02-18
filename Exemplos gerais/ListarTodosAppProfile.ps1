# Para utilizar esse projeto, carregue as funcaoes disponiveis no modulo: Windows\Dev Tools\devtools.psm1

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