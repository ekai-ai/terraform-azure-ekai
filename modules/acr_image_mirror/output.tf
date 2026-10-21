output "mirrored_images" {
  description = "Map of mirrored images — keyed by input key, value is the full ACR ref."
  value = {
    for k, v in var.images :
    k => "${var.acr_name}.azurecr.io/${v.dest_repo}:${v.dest_tag}"
  }
}

# Per-image dest_tag, exposed so downstream layers can pin Helm charts to
# the exact mirrored tag (avoids chart-default vs mirrored-tag drift).
output "mirrored_image_tags" {
  description = "Map of mirrored image keys → their dest_tag (just the tag, no registry/repo)."
  value       = { for k, v in var.images : k => v.dest_tag }
}
