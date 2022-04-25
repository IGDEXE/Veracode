# Script para utilizar para configurar pela primeira vez um Linux com Veracode

# Cria a pasta de ferramentas
mkdir $home/Veracode
echo "Entrando em: home/Veracode"
cd $home/Veracode

# Faz o download das ferramentas nela
echo "Download Wrapper"
curl -L -o VeracodeJavaAPI.jar "https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/20.12.7.3/vosp-api-wrappers-java-20.12.7.3.jar"

echo "Download e configuracao do Pipeline Scan"
curl -sSO https://downloads.veracode.com/securityscan/pipeline-scan-LATEST.zip
unzip pipeline-scan-LATEST.zip
rm -rf pipeline-scan-LATEST.zip

# Add ao Path a pasta
export PATH="$HOME/Veracode:$PATH"