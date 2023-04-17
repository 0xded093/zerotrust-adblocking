#!/bin/bash
# Delete previous policy
curl --request GET --url https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_TEAM_ID/gateway/rules --header "Content-Type: application/json" --header "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" --header "X-Auth-Key: $CLOUDFLARE_AUTH_KEY" | jq ".result[]" | jq "select(.name=='DNS Blocklist').id" | { read uuid; curl --request DELETE --url https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_TEAM_ID/gateway/rules/$uuid --header "Content-Type: application/json" --header "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" --header "X-Auth-Key: $CLOUDFLARE_AUTH_KEY"}
  
# Delete all the previous lists 
curl --request GET --url https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_TEAM_ID/gateway/lists --header "Content-Type: application/json" --header "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" --header "X-Auth-Key: $CLOUDFLARE_AUTH_KEY" | for i in $(jq ".result[].id") ;do curl --request DELETE --url https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_TEAM_ID/gateway/lists/$i --header "Content-Type: application/json" --header "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" --header "X-Auth-Key: $CLOUDFLARE_AUTH_KEY" ; done;

