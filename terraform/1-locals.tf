# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# KQL Demo Lab
# Dec 2024
#
# Terraform file to create 2 VMs, 2 CosmosDB instances, & 4 storage accounts with varying network exposure.
# Resources can be used with "Advent of Cyber" video on reviewing these resources with the Azure Resource Graph Explorer. 
#
# WARNING: This will create resources with public network exposure in your Azure tenant. Recommend using a test environment.
#
# To start: terraform init, terraform apply
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# 1. Locals
# Also creates the resource group `kql-demo-env-rg`.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

locals {
  resource_prefix = "kql-demo-env"
  vm_config = {
    vm1 = {
      suffix          = "win"
      os_type         = "Windows"
      image_publisher = "MicrosoftWindowsServer"
      image_offer     = "WindowsServer"
      image_sku       = "2019-Datacenter"
      image_version   = "latest"
      allowed_port    = 3389
    }
    vm2 = {
      suffix          = "linux"
      os_type         = "Linux"
      image_publisher = "Canonical"
      image_offer     = "0001-com-ubuntu-server-jammy"
      image_sku       = "22_04-lts"
      image_version   = "latest"
      allowed_port    = 443
    }
  }
  cosmosdb_config = {
    cdb1 = {
      suffix = "cdb1"
      public = true
    }
    cdb2 = {
      suffix = "cdb2"
      public = false
    }
  }
  # Variables need to be shortened for 24 character limits (which count vars)
  storage_config_public = {
    s1 = {
      s                = "s1"
      container_public = "blob"
    }
  }
  storage_config_restricted = {
    s2 = {
      s                = "s2"
      container_public = "private"
    }
  }
  storage_config_private = {
    s3 = {
      s = "s3"
    }
  }
}

# Get user's current IP for storage account access rules
data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

# Get environment info to build RG URL
data "azurerm_client_config" "current" {
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Random
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "random_password" "password" {
  length           = 64
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_integer" "int" {
  min = 10000
  max = 99999
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Resource Group
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #

resource "azurerm_resource_group" "lab_environment" {
  name     = "${local.resource_prefix}-rg"
  location = "West US"
}