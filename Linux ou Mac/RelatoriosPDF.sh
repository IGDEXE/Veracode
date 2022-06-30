# Configuracoes de uso
veracodeAppName=""
CaminhoArquivo=""
veracodeID=""
veracodeAPIkey=""
numeroVersao=$(date +%H%M%s%d%m%y)
pastaRelatorios="reports/$veracodeAppName/$numVersao"
ArquivoLog='LOG.txt'
TempoEspera=60s

# Cria a pasta de relatorios
mkdir -p $pastaRelatorios

# Download
urlDownloadAPI="https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/20.12.7.3/vosp-api-wrappers-java-20.12.7.3.jar"
curl -L -o VeracodeJavaAPI.jar $urlDownloadAPI

# Inicia o Scan sem aguardar
java -jar VeracodeJavaAPI.jar \
    -vid $veracodeID -vkey $veracodeAPIkey \
    -action uploadandscan \
    -appname "$veracodeAppName" \
    -filepath "$CaminhoArquivo" \
    -version $numeroVersao \
    -toplevel true \
    -createprofile true 

# Obtem os IDs do Scan
veracodeAppID=$(java -verbose -jar VeracodeJavaAPI.jar -vid $veracodeID -vkey $veracodeAPIkey -action GetAppList | grep -w "$veracodeAppName" | sed -n 's/.* app_id=\"\([0-9]*\)\" .*/\1/p')
veracodeBuildID=$(java -verbose -jar VeracodeJavaAPI.jar -vid $veracodeID -vkey $veracodeAPIkey -action getbuildinfo -appid "$veracodeAppID" | grep -w "$numeroVersao" | sed -n 's/.* build_id=\"\([0-9]*\)\" .*/\1/p')

# Cria um loop para verificar se o scan terminou
echo "Scan em andamento"
echo "ID Scan: $veracodeBuildID - Versão: $numeroVersao"
echo "Aguardando $TempoEspera em cada ciclo..."
while true;
do
    # Acao para pegar as informacoes do scan
    java -jar VeracodeJavaAPI.jar \
        -vid $veracodeID -vkey $veracodeAPIkey \
        -action getbuildinfo \
        -appid "$veracodeAppID" >> $ArquivoLog
    # Valida o status
    scan_result=$(cat $ArquivoLog | grep -Po 'status="\K.*?(?=")')
    if [[ $scan_result = *"Results Ready"* ]];
    then
        break;
    fi
    sleep $TempoEspera
    echo '.'
done

# Gera o relatorio detalhado em PDF
echo "Gerando os relatorios"
# SAST
java -jar VeracodeJavaAPI.jar \
    -vid $veracodeID -vkey $veracodeAPIkey \
    -action detailedreport \
    -buildid "$veracodeBuildID" \
    -format pdf \
    -outputfilepath $pastaRelatorios/SAST.pdf
# SCA
java -jar VeracodeJavaAPI.jar \
    -vid $veracodeID -vkey $veracodeAPIkey \
    -action thirdpartyreport \
    -buildid "$veracodeBuildID" \
    -format pdf \
    -outputfilepath $pastaRelatorios/SCA.pdf
echo "Relatorios disponiveis em:"
echo "$pastaRelatorios"