#! /bin/bash


# copied form https://github.com/dfinity/sns-testing/blob/main/install.sh

cd $PJ_ROOT/bin

curl -L "https://download.dfinity.systems/ic/${IC_COMMIT}/openssl-static-binaries/x86_64-${OS}/sns.gz" -o sns.gz
gzip -fd sns.gz
mv sns sns-cli
chmod +x sns-cli

if [[ "${OS}" == "linux" ]]
then
  export QUILL="linux"
elif [[ "${OS}" == "darwin" ]]
then
  export QUILL="macos"
else
  echo "Unknown OS!"
  exit 1
fi

curl -L "https://github.com/dfinity/sns-quill/releases/download/v0.4.2-beta.1/sns-quill-${QUILL}-x86_64" -o sns-quill
chmod +x sns-quill

curl -L "https://github.com/dfinity/quill/releases/download/v0.4.0/quill-${QUILL}-x86_64" -o quill
chmod +x quill

if [[ "${OS}" == "linux" ]]
then
  export DIDC="linux64"
elif [[ "${OS}" == "darwin" ]]
then
  export DIDC="macos"
else
  echo "Unknown OS!"
  exit 1
fi

curl -L "https://github.com/dfinity/candid/releases/download/2022-11-17/didc-${DIDC}" -o didc
chmod +x didc