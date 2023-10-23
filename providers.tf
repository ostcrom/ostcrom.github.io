terraform {
 required_providers {
  azurerm = {
   source = "hashicorp/azurerm"
   version = "=3.76.0"
  }
  random = {
   source = "hashicorp/random"
   version = "=3.5.1"
  }
  time = {
   source = "hashicorp/time"
   version = "=0.9.1"
  }
 }
}
