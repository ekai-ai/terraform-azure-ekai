locals {
  module_tag = {
    "module" = basename(abspath(path.module))
  }
  tags = merge(var.tags, local.module_tag)
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = var.name
  location            = var.region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  tags                = local.tags
  retention_in_days   = 30


  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}
