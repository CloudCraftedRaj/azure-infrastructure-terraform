############################################
# 1) Create new RG
############################################
resource "azurerm_resource_group" "rg" {
    name = "rg-terraform-practise-learning"
    location = "southindia"
}

############################################
# 2) Creating a random string
############################################
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

############################################
# 3) Create new ADLS account
############################################
resource "azurerm_storage_account" "datalake" {
  name                     = "learningshivadl${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # ADLS Gen2
  is_hns_enabled           = true

  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false
}

# creating new two containers (landings and thirdparty)in ADLS
resource "azurerm_storage_data_lake_gen2_filesystem" "landings" {
  name               = "landings"
  storage_account_id = azurerm_storage_account.datalake.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "thirdparty" {
  name               = "thirdparty"
  storage_account_id = azurerm_storage_account.datalake.id
}

############################################
# 4) Create new data factory account
############################################
resource "azurerm_data_factory" "adf" {
  name                = "learningshivadatafactory-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "SystemAssigned"
  }
}
