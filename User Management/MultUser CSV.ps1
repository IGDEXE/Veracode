# Recebe o caminho do CSV, que precisa estar no formado:
# Nome, Sobrenome, Email, Time (Conforme cadastrado na plataforma previamente)
param (
        [parameter(position=0,Mandatory=$True)]
        $caminhoListaUsuarios
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

# Configurações
$roles = "Greenlight IDE User,Security Insights,Reviewer,Sandbox User"

# Recebe o login
$credenciais = Get-VeracodeCredentials
$VeracodeID = $credenciais[0]
$VeracodeAPIKey = $credenciais[1]

# Faz a configuracao do Header
$Header = 'Nome', 'Sobrenome', 'Email', 'Squad'

# Faz a criação dos usuarios conforme lista
$listaUsuarios = Import-Csv -Path $caminhoListaUsuarios -Header $Header -Delimiter ";"
foreach ($usuario in $listaUsuarios) {
    # Faz o tratamento das informações
    $nome = $usuario.Nome
    $sobrenome = $usuario.Sobrenome
    $email = $usuario.Email
    $squad = $usuario.Squad

    # Log de retorno e criação dos usuarios
    VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action createuser -first_name $nome -last_name $sobrenome -email_address $email -roles $roles -teams $squad
    Write-Host "Usuario: $nome $sobrenome"
    Write-Host "Email: $email - Squad: $squad"
}