resource "azurerm_data_factory" "adf" {
  name                = var.adf_name
  location            = var.location
  resource_group_name = var.rg_name

  identity {
    type = "SystemAssigned"
  }
}