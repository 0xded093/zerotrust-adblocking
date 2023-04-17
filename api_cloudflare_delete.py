import requests
import os 
import json 

CLOUDFLARE_TEAM_ID = os.getenv('CLOUDFLARE_TEAM_ID')
CLOUDFLARE_AUTH_EMAIL = os.getenv('CLOUDFLARE_AUTH_EMAIL')
CLOUDFLARE_AUTH_KEY = os.getenv('CLOUDFLARE_AUTH_KEY')

url = "https://api.cloudflare.com/client/v4/accounts/"+CLOUDFLARE_TEAM_ID+"/gateway/lists/"

headers = {
    "Content-Type": "application/json",
    "X-Auth-Email": CLOUDFLARE_AUTH_EMAIL,
    "X-Auth-Key": CLOUDFLARE_AUTH_KEY
}

response = requests.request("GET", url, headers=headers)
print(response.text)

try:
    for policy in json.loads(response.text)['result']:
        if policy["name"] == "DNS Blocklist":
            url = url + policy["id"] 
            response = requests.request("DELETE", url, headers=headers)
            print(response.text)
        else:
            break
except:
    pass
