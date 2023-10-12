data "azurerm_key_vault" "example" {
  name                = "keyvalt-n2"
  resource_group_name = "module2-suong"
}

data "azurerm_key_vault_secret" "username" {
  name         = "tfvmusername"
  key_vault_id = data.azurerm_key_vault.example.id
}

data "azurerm_key_vault_secret" "password" {
  name         = "tfvmpassword"
  key_vault_id = data.azurerm_key_vault.example.id
}