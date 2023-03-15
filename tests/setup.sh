#!/bin/bash

BASE="$1"
USERNAME="$2"
PASSWORD="$3"
WWW="$4"

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
"${CURL[@]}" -d '{"id":"http-app-x","redirectUris":["http://www:8080/openidc-redirect-uri"],"frontchannelLogout":true,"attributes":{"post.logout.redirect.uris":"http://www:8080/admin/logout/?keycloak-logged-out"},"clientAuthenticatorType":"client-secret","secret":"client-secret-very-secret","directAccessGrantsEnabled":true,"protocolMappers":[{"name":"groups","protocol":"openid-connect","protocolMapper":"oidc-group-membership-mapper","config":{"full.path": "false","claim.name":"groups","userinfo.token.claim":"true"}}]}' $BASE/admin/realms/realm-b/clients

echo Checking OpenID Connect UserInfo endpoint.
BOB_TOKEN=$( curl -s --fail-with-body -d "grant_type=password&client_id=http-app-x&client_secret=client-secret-very-secret&username=bob&password=bobovo+heslo" $BASE/realms/realm-b/protocol/openid-connect/token | jq -r '.access_token' )
BOB_CURL+=(curl -H "Authorization: Bearer $BOB_TOKEN" -H "Content-Type: application/json" --no-progress-meter --fail-with-body -w '%{http_code}\n')
"${BOB_CURL[@]}" $BASE/realms/realm-b/protocol/openid-connect/userinfo | jq
# "${CURL[@]}" $BASE/admin/realms/realm-b/clients/http-app-x | jq
DAV_TOKEN=$( curl -s --fail-with-body -d "grant_type=password&client_id=http-app-x&client_secret=client-secret-very-secret&username=david&password=davidovo+heslo" $BASE/realms/realm-b/protocol/openid-connect/token | jq -r '.access_token' )
DAV_CURL+=(curl -H "Authorization: Bearer $DAV_TOKEN" -H "Content-Type: application/json" --no-progress-meter --fail-with-body -w '%{http_code}\n')
"${DAV_CURL[@]}" $BASE/realms/realm-b/protocol/openid-connect/userinfo | jq

curl --no-progress-meter $WWW | grep -q Django

echo OK $0.
