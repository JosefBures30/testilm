#!/bin/sh
set -eu

KEYCLOAK_REALM=http://keycloak:8080/kc/realms/ILM

echo "Waiting for Core readiness..."
curl --retry 90 --retry-connrefused --retry-delay 2 --retry-all-errors \
  -fsS http://localhost:8080/api/v1/health/readiness >/dev/null

echo "Waiting for the imported Keycloak realm..."
curl --retry 90 --retry-connrefused --retry-delay 2 --retry-all-errors \
  -fsS "$KEYCLOAK_REALM/.well-known/openid-configuration" >/dev/null

CERT_PEM=$(cat /certs/admin-cert.pem)
CERT_DATA=$(printf '%s' "$CERT_PEM" | tr -d '[:space:]' \
  | sed 's/-----BEGINCERTIFICATE-----//;s/-----ENDCERTIFICATE-----//')
if [ -z "$CERT_DATA" ]; then
  echo "Generated Core admin certificate is empty." >&2
  exit 1
fi
ADMIN_PAYLOAD=$(printf \
  '{"username":"%s","description":"ILM local development admin","firstName":"%s","lastName":"%s","email":"%s","enabled":"true","certificateData":"%s","certificateUuid":""}' \
  "$ILM_ADMIN_USERNAME" "$ILM_ADMIN_FIRST_NAME" "$ILM_ADMIN_LAST_NAME" \
  "$ILM_ADMIN_EMAIL" "$CERT_DATA")
ADMIN_STATUS=$(curl -sS -o /tmp/admin-response -w '%{http_code}' -X POST \
  -H 'content-type: application/json' -d "$ADMIN_PAYLOAD" \
  http://localhost:8080/api/v1/local/admins)
case "$ADMIN_STATUS" in
  2*) echo "Registered the local Core administrator." ;;
  409) echo "The local Core administrator is already registered." ;;
  *)
    cat /tmp/admin-response
    echo "Core administrator registration failed with HTTP $ADMIN_STATUS." >&2
    exit 1
    ;;
esac

curl -fsS -X PUT \
  -H 'content-type: application/json' \
  -d "{\"issuerUrl\":\"http://localhost:8000/kc/realms/ILM\",\"clientId\":\"ilm\",\"clientSecret\":\"${OIDC_CLIENT_SECRET}\",\"authorizationUrl\":\"http://localhost:8000/kc/realms/ILM/protocol/openid-connect/auth\",\"tokenUrl\":\"${KEYCLOAK_REALM}/protocol/openid-connect/token\",\"logoutUrl\":\"http://localhost:8000/kc/realms/ILM/protocol/openid-connect/logout\",\"jwkSetUrl\":\"${KEYCLOAK_REALM}/protocol/openid-connect/certs\",\"scope\":[\"openid\"],\"audiences\":[\"ilm\"],\"postLogoutUrl\":\"http://localhost:8000/administrator/\",\"skew\":60}" \
  http://localhost:8080/api/v1/settings/authentication/oauth2Providers/internal

echo "Registered the local Keycloak provider with Core."
