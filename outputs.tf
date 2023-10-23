output "dns_nameserver_json" {
  value = azurerm_dns_zone.zone.name_servers
}
