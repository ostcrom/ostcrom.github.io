provider "azurerm" {
  features {}

  subscription_id   = var.azure_subscription_id
  tenant_id         = var.azure_tenant_id
  client_id         = var.azure_client_id
  client_secret     = var.azure_client_secret
  skip_provider_registration = true
}

import {
 to = azurerm_resource_provider_registration.CdnRegistration
 id = "/subscriptions/${var.azure_subscription_id}/providers/Microsoft.Cdn"
}

#Registering this resource provider to avoid errors complaining
#about DNS when deleting CDN Custom domains.
#Per this post: 
#https://discuss.hashicorp.com/t/is-it-possible-to-change-the-destroy-order/30303/8
resource "azurerm_resource_provider_registration" "CdnRegistration"{
 name = "Microsoft.Cdn"

 feature {
  name = "BypassCnameCheckForCustomDomainDeletion"
  registered = true
 }
}


resource "azurerm_resource_group" "rg" {
 location	= var.location
 name		= random_pet.rg_name.id
}

resource "azurerm_storage_account" "storage" {
 name = format("%s%s", random_string.instance_string.id, "stg")
 account_tier = "Standard"
 location = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name
 account_replication_type = "GRS"
 account_kind = "StorageV2"

 static_website {
  index_document = "index.html"
 }
}


resource "azurerm_storage_blob" "web_blob" {
 for_each = fileset(path.module, "www/**")

 name = trim(each.key, "www/")
 storage_account_name = azurerm_storage_account.storage.name
 storage_container_name = "$web"
 type = "Block"
 content_type = lookup(var.content_map, regex("\\.[^.]+$", each.value), null)
 source = each.key
}

resource "azurerm_cdn_profile" "profile" {
 name = "profile-${random_string.instance_string.id}"
 location = azurerm_resource_group.rg.location
 resource_group_name = azurerm_resource_group.rg.name
 sku = var.cdn_sku 

}

resource "azurerm_cdn_endpoint" "endpoint" {
  name                          = "endpoint-${random_string.instance_string.id}"
  profile_name                  = azurerm_cdn_profile.profile.name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  is_http_allowed               = true
  is_https_allowed              = true
  querystring_caching_behaviour = "IgnoreQueryString"
  is_compression_enabled        = true
  content_types_to_compress = [
    "application/eot",
    "application/font",
    "application/font-sfnt",
    "application/javascript",
    "application/json",
    "application/opentype",
    "application/otf",
    "application/pkcs7-mime",
    "application/truetype",
    "application/ttf",
    "application/vnd.ms-fontobject",
    "application/xhtml+xml",
    "application/xml",
    "application/xml+rss",
    "application/x-font-opentype",
    "application/x-font-truetype",
    "application/x-font-ttf",
    "application/x-httpd-cgi",
    "application/x-javascript",
    "application/x-mpegurl",
    "application/x-opentype",
    "application/x-otf",
    "application/x-perl",
    "application/x-ttf",
    "font/eot",
    "font/ttf",
    "font/otf",
    "font/opentype",
    "image/svg+xml",
    "text/css",
    "text/csv",
    "text/html",
    "text/javascript",
    "text/js",
    "text/plain",
    "text/richtext",
    "text/tab-separated-values",
    "text/xml",
    "text/x-script",
    "text/x-component",
    "text/x-java-source",
  ]

  origin {
    name      = "origin1"
    host_name = azurerm_storage_account.storage.primary_web_host
  }
 origin_host_header = azurerm_storage_account.storage.primary_web_host
delivery_rule {
 name = "ForwardToHTTPS"
 order = 2
 request_scheme_condition {
  operator = "Equal"
  match_values = ["HTTP"]
 }

 url_redirect_action {
  redirect_type = "Found"
  protocol = "Https"
  hostname = "www.danielsteinke.com"
 }
}
delivery_rule {
 name = "ForwardToWWW"
 order = 1
 request_uri_condition {
  operator = "BeginsWith"
  match_values = ["danielsteinke.com"]
 }

 url_redirect_action {
  redirect_type = "Found"
  protocol = "Https"
  hostname = "www.danielsteinke.com"
 }
}
 
}

resource "azurerm_cdn_endpoint_custom_domain" "dscom_www_domain" {
 name = "cdn-domain-www-${random_string.instance_string.id}"
 cdn_endpoint_id = azurerm_cdn_endpoint.endpoint.id
 host_name = "www.${var.target_domain}"

 depends_on = [azurerm_dns_a_record.www, azurerm_dns_cname_record.cdnverify_www, time_sleep.wait_five_minutes]
 cdn_managed_https {
  certificate_type = "Dedicated"
  protocol_type = "ServerNameIndication"
 }
}

resource "azurerm_cdn_endpoint_custom_domain" "dscom_apex_domain" {
 depends_on = [azurerm_dns_a_record.apex, azurerm_dns_cname_record.cdnverify_apex, time_sleep.wait_five_minutes]
 name = "cdn-domain-apex-${random_string.instance_string.id}"
 cdn_endpoint_id = azurerm_cdn_endpoint.endpoint.id
 host_name = "${var.target_domain}"

}
