############################################
# 1) Create new RG
############################################
resource "azurerm_resource_group" "rg" {
    name = "rg-terraform-data-project"
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
  name                     = "data-projectdl${random_string.suffix.result}"
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
  name                = "data-projectdatafactory-tf"
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
  name                         = "data-projectmysqldbserver-tf"
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
  name      = "data-projectsqldb-tf"
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

locals {
  # ARM template you exported from OLD ADF
  adf_template = file("${path.module}/adf_arm/ARMTemplateForFactory.json")

  # NEW ADLS Gen2 endpoint (your Terraform storage account)
  adls_url = "https://${azurerm_storage_account.datalake.name}.dfs.core.windows.net/"

  # NEW SQL connection (your Terraform SQL server/db)
  sql_server_fqdn = "${azurerm_mssql_server.sqlserver.name}.database.windows.net"
  sql_database    = azurerm_mssql_database.sqldb.name

  # These parameter keys MUST match the exported ARMTemplateParametersForFactory.json
  adf_parameters = {
    factoryName = {
      value = azurerm_data_factory.adf.name
    }

    AzureDataLakeStorage1_accountKey = {
      value = azurerm_storage_account.datalake.primary_access_key
    }

    AzureDataLakeStorage1_properties_typeProperties_url = {
      value = local.adls_url
    }

    AzureSqlDatabaseConnection_properties_typeProperties_server = {
      value = local.sql_server_fqdn
    }

    AzureSqlDatabaseConnection_properties_typeProperties_database = {
      value = local.sql_database
    }

    AzureSqlDatabaseConnection_properties_typeProperties_userName = {
      value = var.sql_admin_username
    }

    AzureSqlDatabaseConnection_password = {
      value = var.sql_admin_password
    }

    RestService1_properties_typeProperties_url = {
      value = "https://restcountries.com/v3.1/name"
    }
  }
}

############################################
# 7)Import already existing pipeline,links,datasets JSON Config files to New ADF
############################################

resource "azurerm_resource_group_template_deployment" "adf_import" {
  name                = "import-adf-artifacts"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"

  template_content   = local.adf_template
  parameters_content = jsonencode(local.adf_parameters)

  depends_on = [
    azurerm_data_factory.adf,
    azurerm_storage_account.datalake,
    azurerm_mssql_database.sqldb
  ]
}