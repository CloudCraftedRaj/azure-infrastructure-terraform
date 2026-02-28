


resource "azurerm_mssql_server" "sqlserver" {
  # Must be globally unique
  name                         = var.sql_server_name
  resource_group_name          = var.rg_name
  location                     = var.location

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

# Allow Azure services (ADF, etc.) to access SQL
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = module.sql.sql_server_id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Allow your laptop/public IP so you can connect from DBeaver
resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "AllowMyLocalIP"
  server_id        = module.sql.sql_server_id
  start_ip_address = var.local_ip
  end_ip_address   = var.local_ip
}