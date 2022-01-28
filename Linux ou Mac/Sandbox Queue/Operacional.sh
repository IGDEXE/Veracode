# Configurações
numeroVersao=$(date +%H%M%s%d%m%y)
caminhoArquivo=""
veracodeAppName="Teste - SB Fila"
arquivoLOG="$veracodeAppName.txt"

# Lista de SBs
listaSB=("SB_Dev00" "SB_Dev01" "SB_Dev02" "SB_Dev03" "SB_Dev04" "SB_Dev05" "SB_Dev06" "SB_Dev07" "SB_Dev08")

# Recebe o App ID com base no nome da aplicacao dentro do Veracode
VeracodeAppID=$(java -verbose -jar veracode-wrapper.jar -vid $veracodeID -vkey $veracodeAPIkey -action GetAppList | grep -w "$veracodeAppName" | sed -n 's/.* app_id=\"\([0-9]*\)\" .*/\1/p')

# Verifica se a lista de SBs já existe
##[xml]$INFO = $(java -jar veracode-wrapper.jar -vid "$veracodeID" -vkey "$veracodeAPIkey" -action getsandboxlist -appid "$VeracodeAppID")
##$nomeSBs = $INFO.sandboxlist.sandbox.sandbox_name
for SB in "${listaSB[@]}"
do
    # Compara com as SBs existentes
    if [[ ! " ${listaSB[*]} " =~ " ${SB} " ]]; then
        java -jar veracode-wrapper.jar -vid "$veracodeID" -vkey "$veracodeAPIkey" -action createsandbox -appid "$VeracodeAppID" -sandboxname "$SB"
    fi
done

# Faz o scan na Sandbox selecionada
for sbDisponivel in ${listaSB[@]}
do
    echo "Verificando Sandbox ${sbDisponivel}"
    java -jar veracode-wrapper.jar -vid $veracodeID -vkey $veracodeAPIkey -action UploadAndScan -appname "$veracodeAppName" -createprofile true -sandboxname "$sbDisponivel" -filepath "$caminhoArquivo" -version $numeroVersao > $arquivoLOG 2>&1
    # Verifica o scan
    resultado=$(cat $arquivoLOG)
    if [ $upload_scan_results == *"Starting pre-scan verification for application"* ];
         echo "Scan iniciado na Sandbox $sbDisponivel"
         break
    fi
done