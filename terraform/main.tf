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

############################################
# 5) Azure SQL Server 
############################################
resource "azurerm_mssql_server" "sqlserver" {
  # Must be globally unique
  name                         = "learningshivamysqldbserver-tf"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location

  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
}

############################################
# 6) Azure SQL DB with sample database
############################################
resource "azurerm_mssql_database" "sqldb" {
  name      = "learningshivasqldb-tf"
  server_id = azurerm_mssql_server.sqlserver.id

  sku_name   = "Basic"

  # This creates the SalesLT schema/data (AdventureWorksLT sample)
  sample_name = "AdventureWorksLT"
}

# Allow Azure services (ADF, etc.) to access SQL
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Allow your laptop/public IP so you can connect from DBeaver
resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "AllowMyIP"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = var.my_public_ip
  end_ip_address   = var.my_public_ip
}