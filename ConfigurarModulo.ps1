Import-Module 

try {
    # Configuracoes
    $urlDownload = ""
    # Faz o download dos modulos
    Invoke-WebRequest -Uri "$urlDownload" -OutFile "$env:LOCALAPPDATA/VeracodeTools.zip"
    # Descompacta arquivos
    Expand-Archive -Path "$env:LOCALAPPDATA/VeracodeTools.zip" -DestinationPath "C:\Program Files\WindowsPowerShell\Modules"
}
catch {
    
}