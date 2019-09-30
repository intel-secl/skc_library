#!/bin/bash

export https_proxy=
export http_proxy=

cwd=$(dirname "$(readlink -f "$0")")
set -x
. ${cwd}/../config

PRIVATE_KEY="pkcs11:token=$TOKENNAME;id=$KEYID_RSA;object=$RSA_LABEL;type=private;pin-value=$PIN"
sed -e "s|@MODULE_PATH@|${REAL_PKCS11_MODULE}|g" -e "s|@ENGINE_PATH@|$ENGINE|g" <"$CURRENT_DIR/engines.cnf.in" >"$DATADIR/engines.cnf"

echo "TESTING RSA ENCRYPT/DECRYPT in SGX MODE=${SGX} AND THIS IS THE SAMPLE BUFFER FOR SIGNING" > $DATADIR/testdata

cmdline="rsautl \
-encrypt \
-engine pkcs11 \
-keyform engine \
-inkey $PRIVATE_KEY \
-in $DATADIR/testdata \
-out $DATADIR/testdata.enc"

echo "set args $cmdline" > ${cwd}/.gdbinit
export OPENSSL_CONF=$DATADIR/engines.cnf

#LD_DEBUG=all \

OPENSSL_CONF=$DATADIR/engines.cnf \
$OPENSSL \
	$cmdline
