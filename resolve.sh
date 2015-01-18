#!/usr/bin/env sh

if [ -z $2 ]; then
  echo "SSL certificate chain resolver"
  echo
  echo "Usage: $0 input.pem output.pem"
  echo
  echo "All certificates are in Base64-encoded PEM format."
  exit
fi


FILENAME=$1
CHAINED_FILENAME=$2

TMP_DIR=$(mktemp -d XXXXX)
echo -n > $CHAINED_FILENAME


# extract the first certificate from input file, to make this script idempotent
CURRENT_FILENAME=$TMP_DIR/$FILENAME
openssl x509 -in $FILENAME -out $CURRENT_FILENAME

# loop over certificate chain using AIA extension, CA Issuers field
I=1
while true; do
  # get certificate subject
  CURRENT_SUBJECT=$(openssl x509 -in $CURRENT_FILENAME -noout -text | grep 'Subject: ' | sed -r 's/^[^:]*: //')

  if [ -z "$CURRENT_SUBJECT" ]; then
    echo "Error (empty subject)."
    exit 1
  fi
  echo "$I: $CURRENT_SUBJECT"

  # write certificate to result
  cat $CURRENT_FILENAME >> $CHAINED_FILENAME

  # get issuer's certificate URL
  PARENT_URL=$(openssl x509 -in $CURRENT_FILENAME -noout -text | grep 'CA Issuers' | sed -r 's/^[^:]*://')

  if [ -z $PARENT_URL ]; then
    echo
    echo "Certificate chain complete."
    echo "Total $I certificate(s) written."
    break
  fi

  # download issuer's certificate, convert from DER to PEM
  PARENT_FILENAME=$TMP_DIR/$(basename $PARENT_URL)
  curl -s -o $PARENT_FILENAME $PARENT_URL
  openssl x509 -in $PARENT_FILENAME -inform der -out $PARENT_FILENAME.pem

  CURRENT_FILENAME=$PARENT_FILENAME.pem
  I=$((I+1))
done


# cleanup
rm -rf $TMP_DIR
