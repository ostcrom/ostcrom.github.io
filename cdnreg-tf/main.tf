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

