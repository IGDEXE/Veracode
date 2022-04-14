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

# Configurações
$roles = "Executive,Greenlight IDE User,Security Insights"

# Recebe o login
$credenciais = Get-VeracodeCredentials
$VeracodeID = $credenciais[0]
$VeracodeAPIKey = $credenciais[1]

# Recebe as informações
$caminhoListaUsuarios = Read-host "Informe o caminho do txt com a lista de emails"

# Faz a criação dos usuarios conforme lista de emails no formato "nome.sobrenome@dominio"
$listaUsuarios = Get-Content $caminhoListaUsuarios
foreach ($usuario in $listaUsuarios) {
    # Faz o tratamento das informações
    $dominio = $usuario.Split("@")[1]
    $nome = $usuario.Split(".")[0]
    $nome = $nome.substring(0,1).toupper()+$nome.substring(1).tolower()
    $sobrenome = $usuario.Split(".")[1]
    $sobrenome = $sobrenome -replace ("@" + $dominio.Split(".")[0]),""
    $sobrenome = $sobrenome.substring(0,1).toupper()+$sobrenome.substring(1).tolower()
    $email = $usuario

    # Log de retorno e criação dos usuarios
    VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action createuser -first_name $nome -last_name $sobrenome -email_address $email -roles $roles
    Write-Host "Usuario: $nome $sobrenome"
    Write-Host "Email: $email"
}