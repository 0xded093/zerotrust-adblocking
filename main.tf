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
  blocklist_raw_lines = compact(split("\n", data.http.blocklist.response_body))

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

data "http" "blocklist" {
  url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
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

