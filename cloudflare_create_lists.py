import requests
import os 
import json 

CLOUDFLARE_TEAM_ID = os.getenv('CLOUDFLARE_TEAM_ID')
CLOUDFLARE_AUTH_EMAIL = os.getenv('CLOUDFLARE_AUTH_EMAIL')
CLOUDFLARE_AUTH_KEY = os.getenv('CLOUDFLARE_AUTH_KEY')

base_url = "https://api.cloudflare.com/client/v4/accounts/"+CLOUDFLARE_TEAM_ID

blocklists = {
    "adguard_dns_filter": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt",
    "adway_default_blocklist": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt",
    "dandelion_sprouts_game_console_adblock_list": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt",
    "perflyst_dandelion_sprout_smart_tv_blocklist_for_adguard_home": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt", 
    "scam_blocklist_by_durablenapkin": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt",
    "urlhaus_filter_online": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt",
    "NOR_dandelion_sprouts_anti_malware_list" : "https://adguardteam.github.io/HostlistsRegistry/assets/filter_13.txt",
    "ITA_filtri_dns": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt",
    "windowsspyblocker_hosts_spy_rules": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_23.txt",
    "curben_phishing_filter": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt",
    "notracking_hosts_blocklists": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_32.txt",
    "steven_blacks_list": "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt"
}

hosts = []

for k,v in blocklists.items():
    content = requests.request("GET", v)
    for line in content.text.splitlines():
        if line.startswith("127.0.0.1") or line.startswith("0.0.0.0"):
            hosts.append(line.split(" ")[1])

unique_hosts = list(set(hosts))

hosts = []
blocklists = {}

batch_size = 1000
counter = 0
blocklist_counter = 0

headers = {
    "Content-Type": "application/json",
    "X-Auth-Email": CLOUDFLARE_AUTH_EMAIL,
    "X-Auth-Key": CLOUDFLARE_AUTH_KEY
}

try:
    print("[+] Preparing environment...")
    for index, host in enumerate(unique_hosts):

        hosts.append(host)
        counter += 1 

        if counter == batch_size:
            blocklist_counter += 1
            blocklists[f"Blocklist {blocklist_counter}"] = hosts
            counter = 0 
            hosts = []

    for blocklist in blocklists:
        print(f"[+] Creating list {blocklist}")

        url = base_url+"/gateway/lists/"

        payload = {
            "name":blocklist, 
            "type":"DOMAIN", 
            "items":[], 
            "description":""
        }

        for hostname in blocklists[blocklist]:
            payload["items"].append({"value":hostname})
        
        response = requests.request("POST", url, headers=headers, json=payload)
    
    blocklists = requests.request("GET", url, headers=headers).json()
    
    blocklists_ids = []
    blocklists_ids.append("dns.fqdn in $")
    for blocklist in blocklists["result"]:
        blocklists_ids.append(blocklist["id"])
        blocklists_ids.append(" or in $")
    
    blocklists_ids.pop()
    

    payload = {
        "action": "block",
        "description": "",
        "enabled": True,
        "filters": ["dns"],
        "name": "Block Blocklists",
        "traffic": ''.join(map(str, blocklists_ids))
    }
    
    url = base_url+"/gateway/rules"
    response = requests.request("POST", url, headers=headers, json=payload)

except Exception as e:
    raise e
