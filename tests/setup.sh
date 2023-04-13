#!/bin/bash

BASE="$1"
USERNAME="$2"
PASSWORD="$3"
WWWO="$4"
WWWS="$5"

for i in $( seq 1 12 ) ; do
	curl --no-progress-meter $BASE > /dev/null && break
	if [ $i == 12 ] ; then exit 1 ; fi
	sleep 5
done

for i in $( seq 1 24 ) ; do
	curl --no-progress-meter -d "grant_type=password&client_id=admin-cli&username=$USERNAME&password=$PASSWORD" $BASE/realms/master/protocol/openid-connect/token > /dev/null && break
	if [ $i == 24 ] ; then exit 1 ; fi
	sleep 5
done

TOKEN=$( curl -s --fail-with-body -d "grant_type=password&client_id=admin-cli&username=$USERNAME&password=$PASSWORD" $BASE/realms/master/protocol/openid-connect/token | jq -r '.access_token' )

set -e
set -o pipefail
test -n "$TOKEN"

declare -a CURL
CURL=(curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --no-progress-meter --fail-with-body -w '%{http_code}\n')
echo Creating three realms.
"${CURL[@]}" -d '{"realm":"realm-a","enabled":true}' $BASE/admin/realms
"${CURL[@]}" -d '{"realm":"realm-b","enabled":true}' $BASE/admin/realms
"${CURL[@]}" -d '{"realm":"realm-c","enabled":true}' $BASE/admin/realms

echo Creating four groups.
"${CURL[@]}" -d '{"name":"group-1"}' $BASE/admin/realms/realm-b/groups
"${CURL[@]}" -d '{"name":"group-2"}' $BASE/admin/realms/realm-b/groups
"${CURL[@]}" -d '{"name":"group-3"}' $BASE/admin/realms/realm-b/groups
"${CURL[@]}" -d '{"name":"admins"}' $BASE/admin/realms/realm-b/groups

echo Creating two users.
"${CURL[@]}" -d '{"username":"bob","firstName":"Robert","lastName":"Chase","email":"robert.chase@example.test","enabled":true,"credentials":[{"type":"password","value":"bobovo heslo","temporary":false}],"groups":["group-3","group-1"]}' $BASE/admin/realms/realm-b/users
"${CURL[@]}" -d '{"username":"david","firstName":"David","lastName":"Křížala","email":"davidk@example.test","enabled":true,"credentials":[{"type":"password","value":"davidovo heslo","temporary":false}],"groups":["group-2","admins"]}' $BASE/admin/realms/realm-b/users

echo Creating openid scope, setting it as default.
"${CURL[@]}" -d '{"name":"openid","id":"d499dfe7-fea4-4d40-ba1b-e0b895798ef2","protocol":"openid-connect","attributes":{"include.in.token.scope": "true"}}' $BASE/admin/realms/realm-b/client-scopes
"${CURL[@]}" -X PUT $BASE/admin/realms/realm-b/default-default-client-scopes/d499dfe7-fea4-4d40-ba1b-e0b895798ef2

echo Creating one client.
"${CURL[@]}" -d '{"id":"http-app-x","redirectUris":["'$WWWO'/openidc-redirect-uri"],"frontchannelLogout":true,"attributes":{"post.logout.redirect.uris":"'$WWWO'/admin/logout/?keycloak-logged-out"},"clientAuthenticatorType":"client-secret","secret":"client-secret-very-secret","directAccessGrantsEnabled":true,"protocolMappers":[{"name":"groups","protocol":"openid-connect","protocolMapper":"oidc-group-membership-mapper","config":{"full.path": "false","claim.name":"groups","userinfo.token.claim":"true"}}]}' $BASE/admin/realms/realm-b/clients

echo Checking OpenID Connect UserInfo endpoint.
BOB_TOKEN=$( curl -s --fail-with-body -d "grant_type=password&client_id=http-app-x&client_secret=client-secret-very-secret&username=bob&password=bobovo+heslo" $BASE/realms/realm-b/protocol/openid-connect/token | jq -r '.access_token' )
BOB_CURL+=(curl -H "Authorization: Bearer $BOB_TOKEN" -H "Content-Type: application/json" --no-progress-meter --fail-with-body -w '%{http_code}\n')
"${BOB_CURL[@]}" $BASE/realms/realm-b/protocol/openid-connect/userinfo | jq
# "${CURL[@]}" $BASE/admin/realms/realm-b/clients/http-app-x | jq
DAV_TOKEN=$( curl -s --fail-with-body -d "grant_type=password&client_id=http-app-x&client_secret=client-secret-very-secret&username=david&password=davidovo+heslo" $BASE/realms/realm-b/protocol/openid-connect/token | jq -r '.access_token' )
DAV_CURL+=(curl -H "Authorization: Bearer $DAV_TOKEN" -H "Content-Type: application/json" --no-progress-meter --fail-with-body -w '%{http_code}\n')
"${DAV_CURL[@]}" $BASE/realms/realm-b/protocol/openid-connect/userinfo | jq

echo Get the SAML IdP metadata.
curl --no-progress-meter -o /etc/httpd/saml2/idp_metadata.xml $BASE/realms/realm-b/protocol/saml/descriptor

echo Creating SAML client.
openssl req -x509 -newkey rsa:4096 -subj '/CN=http-app-s' -nodes -keyout /etc/httpd/saml2/mellon.key -outform DER -out /etc/httpd/saml2/mellon.crt -sha256 -days 365
openssl x509 -in /etc/httpd/saml2/mellon.crt -out /etc/httpd/saml2/mellon.pem
"${CURL[@]}" $BASE/admin/realms/realm-b/clients --data-binary @-<<EOS
{
  "id": "http-app-s",
  "clientId": "$WWWS/saml-redirect-uri/metadata",
  "protocol":"saml",
  "redirectUris": ["$WWWS/saml-redirect-uri/postResponse"],
  "attributes": {
    "saml_name_id_format": "username",
    "saml_force_name_id_format": "true",
    "saml_single_logout_service_url_redirect": "$WWWS/admin/logout/?keycloak-logged-out",
    "saml.signing.certificate": "$( base64 -w0 /etc/httpd/saml2/mellon.crt )"},
    "protocolMappers": [
      {
        "name": "X500 surname",
        "protocol": "saml",
        "protocolMapper": "saml-user-property-mapper",
        "consentRequired": false,
        "config": {
          "attribute.nameformat": "Basic",
          "user.attribute": "lastName",
          "friendly.name": "surname",
          "attribute.name": "last_name"
        }
      },
      {
        "name": "X500 givenName",
        "protocol": "saml",
        "protocolMapper": "saml-user-property-mapper",
        "consentRequired": false,
        "config": {
          "attribute.nameformat": "Basic",
          "user.attribute": "firstName",
          "friendly.name": "givenName",
          "attribute.name": "first_name"
        }
      },
      {
        "name": "X500 email",
        "protocol": "saml",
        "protocolMapper": "saml-user-property-mapper",
        "consentRequired": false,
        "config": {
          "attribute.nameformat": "Basic",
          "user.attribute": "email",
          "friendly.name": "email",
          "attribute.name": "email"
        }
      },
      {
        "name": "groups",
        "protocol": "saml",
        "protocolMapper": "saml-group-membership-mapper",
        "consentRequired": false,
        "config": {
          "single": "false",
          "full.path": "false",
          "attribute.name": "groups"
        }
      }
  ]
}
EOS
sed -e "s#urn:someservice#$WWWS/saml-redirect-uri/metadata#" \
	-e "s#https://sp.example.org/#$WWWS/#g" \
	-e "s#<ds:X509Certificate></ds:X509Certificate>#<ds:X509Certificate>$( base64 -w0 /etc/httpd/saml2/mellon.crt )</ds:X509Certificate>#" \
	/mellon_sp_metadata.xml > /etc/httpd/saml2/mellon_metadata.xml

curl --no-progress-meter --retry-delay 1 --retry 5 --retry-connrefused $WWWO | grep -q Django
curl --no-progress-meter $WWWS | grep -q Django

echo OK $0.
