# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tf_mod3"
    storage_account_name = "tfstorageaccountt"
    container_name       = "tfstate"
    key                  = "tf.state"
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}
