import requests
import os 
import json 

CLOUDFLARE_TEAM_ID = os.getenv('CLOUDFLARE_TEAM_ID')
CLOUDFLARE_AUTH_EMAIL = os.getenv('CLOUDFLARE_AUTH_EMAIL')
CLOUDFLARE_AUTH_KEY = os.getenv('CLOUDFLARE_AUTH_KEY')

try:
    print("[+] Getting current rules")
    url = "https://api.cloudflare.com/client/v4/accounts/"+CLOUDFLARE_TEAM_ID+"/gateway/rules/"
    headers = {
        "Content-Type": "application/json",
        "X-Auth-Email": CLOUDFLARE_AUTH_EMAIL,
        "X-Auth-Key": CLOUDFLARE_AUTH_KEY
    }
    response = requests.request("GET", url, headers=headers)

    for rule in json.loads(response.text)['result']:
        if rule["name"] == "DNS Blocklist":
            url = url + rule["id"] 
            print("[-] Deleting rule:", rule["id"])
            response = requests.request("DELETE", url, headers=headers)
            print(response.text)

    print("[+] Getting current lists")
    url = "https://api.cloudflare.com/client/v4/accounts/"+CLOUDFLARE_TEAM_ID+"/gateway/lists/"
    response = requests.request("GET", url, headers=headers)

    for list in json.loads(response.text)['result']:
        url2 = url + list["id"] 
        print("[-] Deleting list:", list["id"])
        response = requests.request("DELETE", url2, headers=headers)
        print(response.text)
except:
    pass
      
