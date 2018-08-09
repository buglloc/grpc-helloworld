#!/bin/bash -ex

CA_DIR="/tmp/ca"
ICA_DIR="/tmp/ca/intermediate"
rm -rf $CA_DIR
mkdir -p $CA_DIR/{newcerts,certs,private,csr}
mkdir -p $ICA_DIR/{newcerts,certs,private,csr}
touch $CA_DIR/index{.txt,.txt.attr} $ICA_DIR/index{.txt,.txt.attr}
echo 10 > $CA_DIR/serial
echo 10 > $ICA_DIR/serial

# Generate RootCA
openssl genrsa -passout pass:1234 -aes256 -out $CA_DIR/private/root_ca.key 4096
openssl rsa -passin pass:1234 -in $CA_DIR/private/root_ca.key -out $CA_DIR/private/root_ca.key
openssl req -config ./openssl.d/root.cnf -new -x509 -sha256 -extensions v3_ca -key $CA_DIR/private/root_ca.key -out $CA_DIR/certs/root_ca.crt -days 7300 -set_serial 0 -subj "/C=RU/O=Test/OU=Test/CN=RootCA"

# Generate IntermediateCA_1
openssl req -config ./openssl.d/intermediate_1.cnf -nodes -new -newkey rsa:4096 -keyout $ICA_DIR/private/intermediate_1.key -out $ICA_DIR/csr/intermediate_1.csr -subj "/C=RU/O=Test/OU=Test/CN=IntermediateCA_1"
openssl ca -batch -config ./openssl.d/root.cnf -extensions v3_intermediate_ca -days 3650 -notext -in $ICA_DIR/csr/intermediate_1.csr -out $ICA_DIR/certs/intermediate_1.crt 
cat $ICA_DIR/certs/intermediate_1.crt $CA_DIR/certs/root_ca.crt > $ICA_DIR/certs/intermediate_1_bundle.crt

# Generate IntermediateCA_2
openssl req -config ./openssl.d/intermediate_2.cnf -nodes -new -newkey rsa:4096 -keyout $ICA_DIR/private/intermediate_2.key -out $ICA_DIR/csr/intermediate_2.csr -subj "/C=RU/O=Test/OU=Test/CN=IntermediateCA_2"
openssl ca -batch -config ./openssl.d/root.cnf -extensions v3_intermediate_ca -days 3650 -notext -in $ICA_DIR/csr/intermediate_2.csr -out $ICA_DIR/certs/intermediate_2.crt
cat $ICA_DIR/certs/intermediate_2.crt $CA_DIR/certs/root_ca.crt > $ICA_DIR/certs/intermediate_2_bundle.crt

# Generate Server Key/Cert
openssl req -config ./openssl.d/intermediate_1.cnf -nodes -new -newkey rsa:2048 -keyout $ICA_DIR/private/server.key -out $ICA_DIR/csr/server.csr -subj "/C=RU/O=Test/OU=Server/CN=localhost"
openssl ca -batch -config ./openssl.d/intermediate_1.cnf -extensions server_cert -days 365 -notext -in $ICA_DIR/csr/server.csr -out $ICA_DIR/certs/server.crt
cat $ICA_DIR/certs/server.crt $ICA_DIR/certs/intermediate_1_bundle.crt > $ICA_DIR/certs/server_bundle.crt

# Generate valid Client Key/Cert on IntermediateCA_1
openssl req -config ./openssl.d/intermediate_1.cnf -nodes -new -newkey rsa:2048 -keyout $ICA_DIR/private/client_1.key -out $ICA_DIR/csr/client_1.csr -subj "/C=RU/O=Test/OU=Client/CN=Client_1"
openssl ca -batch -config ./openssl.d/intermediate_1.cnf -extensions client_cert -days 365 -notext -in $ICA_DIR/csr/client_1.csr -out $ICA_DIR/certs/client_1.crt
cat $ICA_DIR/certs/client_1.crt $ICA_DIR/certs/intermediate_1_bundle.crt > $ICA_DIR/certs/client_1_bundle.crt

# Generate valid Client Key/Cert on IntermediateCA_2
openssl req -config ./openssl.d/intermediate_2.cnf -nodes -new -newkey rsa:2048 -keyout $ICA_DIR/private/client_2.key -out $ICA_DIR/csr/client_2.csr -subj "/C=RU/O=Test/OU=Client/CN=Client_2"
openssl ca -batch -config ./openssl.d/intermediate_2.cnf -extensions client_cert -days 365 -notext -in $ICA_DIR/csr/client_2.csr -out $ICA_DIR/certs/client_2.crt
cat $ICA_DIR/certs/client_2.crt $ICA_DIR/certs/intermediate_2_bundle.crt > $ICA_DIR/certs/client_2_bundle.crt

cp -f $ICA_DIR/certs/intermediate_1.crt trusted_ca_for_server_single.crt
cp -f $ICA_DIR/certs/intermediate_1_bundle.crt trusted_ca_for_server_bundle.crt
cp -f $ICA_DIR/certs/intermediate_1_bundle.crt trusted_ca_for_client.crt

cp -f $ICA_DIR/certs/server_bundle.crt .
cp -f $ICA_DIR/private/server.key .
cp -f $ICA_DIR/certs/client_1_bundle.crt .
cp -f $ICA_DIR/private/client_1.key .
cp -f $ICA_DIR/certs/client_2_bundle.crt .
cp -f $ICA_DIR/private/client_2.key .
