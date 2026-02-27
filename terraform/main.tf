############################################
# 1) Create new RG
############################################
resource "azurerm_resource_group" "rg" {
    name = "rg-terraform-practise-learning"
    location = "southindia"
}