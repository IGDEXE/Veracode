# Para utilizar esse projeto, carregue as funcaoes disponiveis no modulo: Windows\Dev Tools\devtools.psm1

# Configuracoes
$manterAppProfile = "" # Nome do perfil que queremos manter

# Recebe todos os perfis da conta
$listaPerfis = Get-AllVeracodeProfiles

# Para cada perfil
foreach ($perfil in $listaPerfis) {
    # Validamos se é o nosso
    if ($perfil -ne $manterAppProfile) {
        # Deletamos o perfil caso não seja o nosso
        Delete-VeracodeAppProfile $perfil
    }
}