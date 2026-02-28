


resource "azurerm_mssql_server" "sqlserver" {
  # Must be globally unique
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location

  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
}

resource "azurerm_mssql_database" "sqldb" {
  name      = var.db_name
  server_id = azurerm_mssql_server.sqlserver.id

  sku_name   = "Basic"

  # This creates the SalesLT schema/data (AdventureWorksLT sample)
  sample_name = "AdventureWorksLT"
}