# Antes de começar, lembre-se de carregar a função disponivel em: 
# PreScan tamanhos.ps1

# Recebe os dados de um arquivo CSV, com a primeira coluna sendo o nome dos perfis 
# E a segunda o caminho do arquivo que vai ser analisado, conforme guia de compilação
$NomeApp = @()
$caminho = @()
Import-Csv -Path $caminhoCSV -delimiter ";"|`
    ForEach-Object {
        try {
            # Recebe os dados
            $NomeApp += $_.Nome
            $caminho += $_.Caminho

            # Faz o scan
            Get-VeracodeAppSize $veracodeID $veracodeAPIkey $NomeApp $caminho
        }
        catch {
            $ErrorMessage = $_.Exception.Message # Recebe o erro
            Write-Host "Erro ao analisar $NomeApp"
            Write-Host "$ErrorMessage"
        }
    }