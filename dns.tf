resource "azurerm_dns_zone" "zone" {
 name = "danielsteinke.com"
 resource_group_name = azurerm_resource_group.rg.name

 provisioner "local-exec" {
  command = <<CMD
make docker-dns-sync GD_API_KEY=${var.gd_api_key} GD_API_SECRET=${var.gd_api_secret} \
GD_SHOPPER_ID=${var.gd_shopper_id} TARGET_DOMAIN=${var.target_domain} NS_DATA=${jsonencode(azurerm_dns_zone.zone.name_servers)}
CMD

 }

}

resource "time_sleep" "wait_five_minutes" {
 depends_on = [azurerm_dns_zone.zone]
 create_duration = "5m"
}


resource "azurerm_dns_mx_record" "mx" {
 zone_name = azurerm_dns_zone.zone.name
 resource_group_name = azurerm_resource_group.rg.name
 
 record {
  preference = 10
  exchange = "mx01.mail.icloud.com"
 }

 name = "@"
 record {
  preference = 10
  exchange = "mx02.mail.icloud.com"
 }
 ttl = 300
}

resource "azurerm_dns_txt_record" "txt" {
 zone_name = azurerm_dns_zone.zone.name
 resource_group_name = azurerm_resource_group.rg.name
 
 name = "@"
 record {
  value = "v=spf1 include:icloud.com ~all"
 }
 ttl = 300
}

resource "azurerm_dns_cname_record" "dkim" {
 zone_name = azurerm_dns_zone.zone.name
 resource_group_name = azurerm_resource_group.rg.name

 name = "sig1._domainkey"
 record = "sig1.dkim.danielsteinke.com.at.icloudmailadmin.com."
 ttl = 300
}

resource "azurerm_dns_a_record" "apex" {
 zone_name = azurerm_dns_zone.zone.name
 resource_group_name = azurerm_resource_group.rg.name
 name = "@"

 target_resource_id = azurerm_cdn_endpoint.endpoint.id
 ttl = 300
}

resource "azurerm_dns_a_record" "www" {
 zone_name = azurerm_dns_zone.zone.name
 resource_group_name = azurerm_resource_group.rg.name

 name = "www"
 target_resource_id = azurerm_cdn_endpoint.endpoint.id
 ttl = 300
}

resource "azurerm_dns_cname_record" "cdnverify_www" {
 zone_name = azurerm_dns_zone.zone.name
 resource_group_name = azurerm_resource_group.rg.name

 name = "cdnverify.www"
 record = "cdnverify.${azurerm_cdn_endpoint.endpoint.fqdn}"
 ttl = 300
}

resource "azurerm_dns_cname_record" "cdnverify_apex" {
 zone_name = azurerm_dns_zone.zone.name
 resource_group_name = azurerm_resource_group.rg.name

 name = "cdnverify"
 record = "cdnverify.${azurerm_cdn_endpoint.endpoint.fqdn}"
 ttl = 300
}
