# Configuracoes de uso
VERACODE_ID="" 
VERACODE_KEY=""

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
    DATA="id=$VERACODE_ID&host=api.veracode.com&url=$URLPATH&method=$METHOD"
    signature=$(echo -n "$DATA" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$signingKey | cut -d ' ' -f 2)
    VERACODE_AUTH_HEADER="VERACODE-HMAC-SHA-256 id=$VERACODE_ID,ts=$TS,nonce=$NONCE,sig=$signature"
}

# Pega a lista de scans
# Lista de scan_type validos: STATIC, DYNAMIC, MANUAL ou SCA
URLPATH=/appsec/v1/applications?scan_type={STATIC}
METHOD=GET
aut_Veracode $URLPATH $METHOD
curl -s -X $METHOD -H "Authorization: $VERACODE_AUTH_HEADER" "https://api.veracode.com$URLPATH"