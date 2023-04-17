terraform {
  cloud {
    organization = "dedins"

    workspaces {
      name = "zerotrust-adblocking-explicit"
    }
  }
}

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

variable "cloudflare_api_token" {
  type = string
}

variable "account_id" {
  type = string
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  dollar_symbol       = "$"    

#   filters = setunion(data.http.adguard_dns_filter.response_body, data.http.adway_default_blocklist.response_body)
  
  
  blocklist_raw_lines = compact(split("\n", data.http.adguard_dns_filter.response_body))
    
  # Extract domains from the hosts file format - removing anything with a leading "-", since that fails validation
  blocklist = [
    for line in local.blocklist_raw_lines : split(" ", line)[1]
    if startswith(line, "0.0.0.0 ") && line != "0.0.0.0 0.0.0.0" && !startswith(line, "0.0.0.0 -")
  ]

  # Create a list of lists, with a maximum of 1000 items per nested list
  blocklist_chunks = [
    for i in range(0, length(local.blocklist), 1000) :
    slice(local.blocklist, i, i + min(length(local.blocklist) - i, 1000))
  ]

  # Build the wirefilter expression to be used with the DNS policy
  rule_traffic_expression = join(" or ", [
    for list in cloudflare_teams_list.blocklist : "dns.fqdn in ${local.dollar_symbol}${list.id}"
  ])
}

data "http" "adguard_dns_filter" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"
}
data "http" "adway_default_blocklist" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt"
}
data "http" "dandelion_sprouts_game_console_adblock_list" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt"
}
data "http" "perflyst_dandelion_sprout_smart_tv_blocklist_for_adguard_home" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt"
}
data "http" "scam_blocklist_by_durablenapkin" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt"
}
data "http" "urlhaus_filter_online" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"
}    
data "http" "NOR_dandelion_sprouts_anti_malware_list" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_13.txt"
}
data "http" "ITA_filtri_dns" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt"
}
data "http" "windowsspyblocker_hosts_spy_rules" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_23.txt"
}        
data "http" "curben_phishing_filter" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt"
}
data "http" "notracking_hosts_blocklists" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_32.txt"
}
data "http" "steven_blacks_list" {
  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt"
}

resource "cloudflare_teams_list" "blocklist" {
  count      = length(local.blocklist_chunks)
  account_id = var.account_id
  name       = "Blocklist ${count.index + 1}"
  type       = "DOMAIN"
  items      = local.blocklist_chunks[count.index]
}

resource "cloudflare_teams_rule" "blocklist_dns_policy" {
  account_id  = var.account_id
  name        = "DNS Blocklist"
  description = "Block all blocklist entries"
  enabled     = true
  precedence  = 1
  action      = "block"
  filters     = ["dns"]
  traffic     = local.rule_traffic_expression
  depends_on = [
    cloudflare_teams_list.blocklist
  ]
}
