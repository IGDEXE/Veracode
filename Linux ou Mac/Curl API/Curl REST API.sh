# Configuracoes de uso
veracodeAppName=""
CaminhoArquivo=""
VERACODE_ID=""
VERACODE_KEY=""

# Feito com base no script disponivel em:
# https://github.com/christyson/Veracode-Upload-and-Scan-Shell-Script/blob/master/veracodeuploadandscan.sh


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
curl -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "https://analysiscenter.veracode.com$URLPATH" -F "app_id=$AppID" -F "auto_scan=true"
