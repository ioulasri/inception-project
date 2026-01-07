#!/bin/bash

# Certificate Generation Script for 1337 Benguérir
# This script generates self-signed SSL certificates for your inception project

# Configuration - Update these with your details
COUNTRY="MA"                    # Morocco
STATE="Marrakech-Safi"         # Region where Benguérir is located (or just "Benguerir")
CITY="Benguerir"               # Your city
ORGANIZATION="1337"            # 1337 or 42
COMMON_NAME="imoulasr.42.fr"  # Your domain

# Output files
CERT_DIR="secrets"
CERT_FILE="${CERT_DIR}/cert.pem"
KEY_FILE="${CERT_DIR}/key.pem"

# Create secrets directory if it doesn't exist
mkdir -p "${CERT_DIR}"

# Generate certificate
echo "🔐 Generating SSL certificate for 1337 Benguérir..."
echo ""
echo "Certificate Details:"
echo "  Country: ${COUNTRY}"
echo "  State: ${STATE}"
echo "  City: ${CITY}"
echo "  Organization: ${ORGANIZATION}"
echo "  Common Name: ${COMMON_NAME}"
echo ""

openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORGANIZATION}/CN=${COMMON_NAME}"

# Set proper permissions
chmod 600 "${KEY_FILE}" "${CERT_FILE}"

echo ""
echo "✅ Certificate generated successfully!"
echo ""
echo "Files created:"
echo "  - ${CERT_FILE}"
echo "  - ${KEY_FILE}"
echo ""
echo "Verify certificate:"
echo "  openssl x509 -in ${CERT_FILE} -noout -subject -dates"
