#!/usr/bin/env sh

if [ -z $2 ]; then
  echo "Usage: $0 input-cert-filename output-chained-cert-filename"
  exit
fi


FILENAME=$1
CHAINED_FILENAME=$2

TMP_DIR=$(mktemp -d)
echo -n > $CHAINED_FILENAME


CURRENT_FILENAME=$FILENAME
I=1

# loop over certificate chain using AIA extension, CA Issuers field
while true; do
  # get certificate subject
  CURRENT_SUBJECT=$(cat $CURRENT_FILENAME | openssl x509 -inform der -noout -text | grep 'Subject: ' | sed -r 's/^[^:]*: //')

  if [ -z "$CURRENT_SUBJECT" ]; then
    echo "Error (empty subject)."
    exit 1
  fi
  echo "$I: $CURRENT_SUBJECT"

  # write certificate to result
  cat $CURRENT_FILENAME >> $CHAINED_FILENAME

  # get issuer certificate
  PARENT_URL=$(cat $CURRENT_FILENAME | openssl x509 -inform der -noout -text | grep 'CA Issuers' | sed -r 's/^[^:]*://')

  if [ -z $PARENT_URL ]; then
    echo
    echo "Certificate chain complete."
    echo "Total $I certificate(s) written."
    break
  fi

  # download issuer certificate
  PARENT_FILENAME=$TMP_DIR/$(basename $PARENT_URL)
  curl -s -o $PARENT_FILENAME $PARENT_URL

  CURRENT_FILENAME=$PARENT_FILENAME
  I=$((I+1))
done

rm -rf $TMP_DIR
