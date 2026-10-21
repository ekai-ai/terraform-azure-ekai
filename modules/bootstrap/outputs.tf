output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "region" {
  value = data.azurerm_resource_group.rg.location
}

output "dns_zone_id" {
  value = local.dns_zone_id
}

output "dns_zone_name" {
  value = local.dns_zone_name
}

# After apply, copy these NS records into the parent zone (ekai.ai) as the
# delegation for `<env>.ekai.ai`. Only populated when manage_dns_zone = true.
output "dns_zone_name_servers" {
  value       = local.dns_zone_name_servers
  description = "NS records to delegate from the parent zone. Empty when manage_dns_zone = false."
}
