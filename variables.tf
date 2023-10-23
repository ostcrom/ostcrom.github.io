variable "location" {
 type = string
 default = "southcentralus"
}

variable "content_map" {
 type = map(string)
 default = {
    ".json":"application/json",
    ".txt":"text/plain",
    ".csv":"text/csv",
    ".png":"image/png",
    ".html":"text/html",
    ".jpg":"image/jpeg",
    ".jpeg":"image/jpeg"
    ".css":"text/css"
 }
}

variable "resource_group_name_prefix" {
  type        = string
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
  default     = "rg"
}

variable "origin_url" {
  type        = string
  description = "Url of the origin."
  default     = "www.contoso.com"
}

variable "cdn_sku" {
  type        = string
  description = "CDN SKU names."
  default     = "Standard_Microsoft"
  validation {
    condition     = contains(["Standard_Akamai", "Standard_Microsoft", "Standard_Verizon", "Premium_Verizon"], var.cdn_sku)
    error_message = "The cdn_sku must be one of the following: Standard_Akamai, Standard_Microsoft, Standard_Verizon, Premium_Verizon."
  }
}

variable "gd_api_key" { type = string }
variable "gd_api_secret" { type = string }
variable "gd_shopper_id" { type = string }
variable "target_domain" { type = string }
variable "azure_subscription_id" { type = string }
variable "azure_tenant_id" { type = string }

variable "azure_client_id" {
 type = string
 sensitive = true
}

variable "azure_client_secret" {
 type = string
 sensitive = true
}
