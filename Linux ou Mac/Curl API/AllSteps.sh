# Configuracoes de uso
veracodeAppName=""
CaminhoArquivo=""
VERACODE_ID=""
VERACODE_KEY=""
numVersao=$(date +%H%M%s%d%m%y)
ArquivoLog=$veracodeAppName'-'$numVersao'.txt'
PRESCAN_SLEEP_TIME=40
SCAN_SLEEP_TIME=60

# Funcao para autenticar
aut_Veracode () {
    # Entrada de dados para a criacao do HMAC Header
    URLPATH=$1
    METHOD=$2

    # Faz a criacao
    NONCE="$(cat /dev/random | xxd -p | head -c 32)"
    TS="$(($(date +%s%N)/1000))"
    encryptedNonce=$(echo "$NONCE" | xxd -r -p | openssl dgst -sha256 -mac HMAC -macopt hexkey:$VERACODE_KEY | cut -d ' ' -f 2)
    encryptedTimestamp=$(echo -n "$TS" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedNonce | cut -d ' ' -f 2)
    signingKey=$(echo -n "vcode_request_version_1" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$encryptedTimestamp | cut -d ' ' -f 2)
    DATA="id=$VERACODE_ID&host=analysiscenter.veracode.com&url=$URLPATH&method=$METHOD"
    signature=$(echo -n "$DATA" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$signingKey | cut -d ' ' -f 2)
    VERACODE_AUTH_HEADER="VERACODE-HMAC-SHA-256 id=$VERACODE_ID,ts=$TS,nonce=$NONCE,sig=$signature"
}

# Pega a listagem de Apps
URLPATH=/api/5.0/getapplist.do
METHOD=GET
aut_Veracode $URLPATH $METHOD
curl -s -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "https://analysiscenter.veracode.com$URLPATH" -o applist.xml

# Obtem o App ID
while read -r line
do
    app_name=$(echo $line | grep -Po 'app_name="\K.*?(?=")')
    AppID=$(echo $line | grep -Po 'app_id="\K.*?(?=")')
    if [ "$app_name" = "$veracodeAppName" ]; then 
    break
    fi
done < <(grep $veracodeAppName applist.xml)


# Faz o Upload do arquivo
URLPATH=/api/5.0/uploadfile.do
METHOD=POST
aut_Veracode $URLPATH $METHOD
echo "Fazendo o Upload do arquivo: $CaminhoArquivo"
curl -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "https://analysiscenter.veracode.com$URLPATH" -F "app_id=$AppID" -F "file=@$CaminhoArquivo"

# Inicia o scan
URLPATH=/api/5.0/beginprescan.do
METHOD=POST
aut_Veracode $URLPATH $METHOD
echo "   "
echo "Iniciando o scan no perfil: $veracodeAppName ID: $AppID"
curl -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "https://analysiscenter.veracode.com$URLPATH" -F "app_id=$AppID" -F "auto_scan=true" -F "scan_all_nonfatal_top_level_modules=true"  > $ArquivoLog 2>&1
BuildID=$(cat $ArquivoLog | grep build_id | awk -F "\"" '{print $2}')

# Atualiza o scan com o numero de versao
URLPATH=/api/5.0/updatebuild.do
METHOD=POST
aut_Veracode $URLPATH $METHOD
echo "Configurando versionamento: $numVersao"
curl -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "https://analysiscenter.veracode.com$URLPATH" -F "app_id=$AppID" -F "version=@$numVersao"

# Verifica o status do scan
while true;
do
    # Acao para pegar as informacoes do scan
    URLPATH=/api/5.0/getprescanresults.do
    METHOD=GET
    aut_Veracode $URLPATH $METHOD
    curl -s -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "https://analysiscenter.veracode.com$URLPATH" -F "app_id=$AppID" > $ArquivoLog 2>&1
    # Valida os status
    scan_status=$(cat $ArquivoLog)
    if [[ $scan_status = *"Scan In Process"* ]];
    then
        echo ""
        echo '[INFO] scan in process ...'
        echo '[INFO] wait 2 more minutes ...'
        sleep $SCAN_SLEEP_TIME
    elif [[ $scan_status = *"Submitted to Engine"* ]];
    then
        echo ""
        echo '[INFO] Application submitted to scan engine'
        echo '[INFO] Scan will start momentarily'
        echo '[INFO] wait 1 more mintue'
        sleep $PRESCAN_SLEEP_TIME
    elif [[ $scan_status = *"Pre-Scan Submitted"* ]];
    then
        echo ""
        echo '[INFO] pre-scan still running ...'
        echo '[INFO] wait 1 more minute ...'
        sleep $PRESCAN_SLEEP_TIME
    else
        scan_finished=$(cat $ArquivoLog)
        if [[ $scan_finished = *"Results Ready"* ]];
        then
            echo ""
            echo '[INFO] scan has finished'
            rm -rf $ArquivoLog
            sleep $SCAN_SLEEP_TIME
            break;
        fi
    fi
done

# Define a quebra de pipeline
echo '[INFO] Scan results'
URLPATH=/api/4.0/summaryreport.do
METHOD=GET
aut_Veracode $URLPATH $METHOD
curl -s -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "https://analysiscenter.veracode.com$URLPATH" -F "build_id=$BuildID" > $ArquivoLog 2>&1
scan_result=$(cat $ArquivoLog)

if [[ $scan_result = *"Did Not Pass"* ]];
then
    echo 'Application: ' $veracodeAppName '(App-ID '$AppID') - Scanname: ' $numVersao '(Build-ID '$BuildID') - Did NOT pass'
    rm -rf $ArquivoLog
    exit 1
else
    echo 'Application: ' $veracodeAppName '(App-ID '$AppID') - Scanname: ' $numVersao '(Build-ID '$BuildID') - Did pass'
    rm -rf $ArquivoLog
    exit 0
fi