try {
    # Configuracoes
    $urlDownload = "https://github.com/IGDEXE/Veracode/blob/8b05a87a08b0d06c7b2fc4ec7a757939fed3934d/Modulo/VeracodeTools.psm1"
    $pastaModulos = "C:\Program Files\WindowsPowerShell\Modules"
    $caminhoModulo = "$pastaModulos/VeracodeTools.psm1"
    # Faz o download dos modulos
    Invoke-WebRequest -Uri "$urlDownload" -OutFile "$caminhoModulo"
    # Faz a importacao
    Import-Module -Name "$caminhoModulo" -Verbose
}
catch {
    $ErrorMessage = $_.Exception.Message # Recebe o erro
    Write-Host "Erro ao importar o modulo"
    Write-Host "$ErrorMessage"
}