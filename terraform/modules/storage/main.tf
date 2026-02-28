resource "azurerm_storage_account" "datalake" {
  name                     = var.storage_account_name
  resource_group_name      = var.rg_name
  location                 = var.location

  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind

  # ADLS Gen2
  is_hns_enabled           = var.is_hns_enabled

  min_tls_version          = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
}

# creating new two containers (landings and thirdparty)in ADLS
resource "azurerm_storage_data_lake_gen2_filesystem" "landings" {
  for_each              = toset(var.filesystems)
  name                  = each.value
  storage_account_id = azurerm_storage_account.datalake.id
}