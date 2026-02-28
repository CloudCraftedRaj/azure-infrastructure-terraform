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

###################################################################################
# 3) Create new ADLS account by default with two containers landings and thirdparty
###################################################################################
module "adls_storage" {
    source                   = "./modules/storage"
    storage_account_name     = "data-projectdl${random_string.suffix.result}"
    rg_name                  = azurerm_resource_group.rg.name
    location                 = azurerm_resource_group.rg.location

    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"

    # ADLS Gen2
    is_hns_enabled           = true

    min_tls_version          = "TLS1_2"
    allow_nested_items_to_be_public = false
}


############################################
# 4) Create new data factory account
############################################
module "adf" {
  source    = "./modules/adf"
  adf_name  = "data-projectdatafactory-tf"
  location  = azurerm_resource_group.rg.location
  rg_name   = azurerm_resource_group.rg.name
}

####################################################
# 5) Azure SQL Server & SQL DB with Firewall Rules
####################################################
module "sql" {
  source                            = "./modules/sql"
  sql_server_name                   = "data-projectmysqldbserver-tf"
  rg_name                           = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  sql_admin_username                = var.sql_admin_username
  sql_admin_password                = var.sql_admin_password
  db_name                           = "data-projectsqldb-tf"
  start_ip_address_localip_address  = var.my_public_ip
  end_ip_address_localip_address    = var.my_public_ip
}

locals {
  # ARM template you exported from OLD ADF
  adf_template = file("${path.module}/adf_arm/ARMTemplateForFactory.json")

  # NEW ADLS Gen2 endpoint (your Terraform storage account)
  adls_url = "https://${module.adls_storage.adls_storage_account_name}.dfs.core.windows.net/"

  # NEW SQL connection (your Terraform SQL server/db)
  sql_server_fqdn = "${module.sql.sql_server_name}.database.windows.net"
  sql_database    = module.sql.db_name

  # These parameter keys MUST match the exported ARMTemplateParametersForFactory.json
  adf_parameters = {
    factoryName = {
      value = module.adf.adf_name
    }

    AzureDataLakeStorage1_accountKey = {
      value = module.adls_storage.primary_access_key
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

#################################################################################
# 7)Import already existing pipeline,links,datasets JSON Config files to New ADF
#################################################################################
resource "azurerm_resource_group_template_deployment" "adf_import" {
  name                = "import-adf-artifacts"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"

  template_content   = local.adf_template
  parameters_content = jsonencode(local.adf_parameters)

  depends_on = [
    module.adf,
    module.adls_storage,
    module.sql
  ]
}