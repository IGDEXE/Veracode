# Credenciais
veracodeID="Disponivel no portal da Veracode"
veracodeAPIkey="Disponivel no portal da Veracode"
export SRCCLR_API_TOKEN="Disponivel no portal da Veracode"

# Configuracoes
appName="Nome da aplicação"
zipArquivo="$appName.zip"
numeroVersao=$(date +%H%M%s%d%m%y)

# URLs
urlDownloadAPI="https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/20.12.7.3/vosp-api-wrappers-java-20.12.7.3.jar"
urlRepoGit='https://github.com/VictorM3/Vulnerability-goapp.git'
urlSCA='https://download.sourceclear.com/ci.sh'

# Faz o download da ferramenta
curl -L -o VeracodeJavaAPI.jar $urlDownloadAPI

# Faz o clone do repositorio
git clone $urlRepoGit

# Processo de build
cd Vulnerability-goapp
go get all
go mod download
go mod vendor

# Veracode SCA
export EXTRA_ARGS='--update-advisor --pull-request'
curl -sSL $urlSCA | bash -s – scan $EXTRA_ARGS --allow-dirty
cd ..

# Empacotamento do resultado
zip -r $zipArquivo Vulnerability-goapp -x *runenv/*

# Veracode SAST
java -jar VeracodeJavaAPI.jar -vid $veracodeID -vkey $veracodeAPIkey -action uploadandscan -appname "$appName" -filepath "$zipArquivo" -version $numeroVersao -createprofile true -scantimeout 60