variable "acr_name" {
  type        = string
  description = "Name of the destination ACR (e.g. ekaiclient1acr)."
}

variable "images" {
  description = "Map of images to mirror. Key is a stable identifier (e.g. \"minio\"); value is source image ref + dest path/tag in our ACR."
  type = map(object({
    source    = string # full source ref, e.g. "docker.io/bitnamilegacy/minio:2025.7.23-debian-12-r3"
    dest_repo = string # path under ACR, e.g. "bitnami/minio"
    dest_tag  = string # tag to use in ACR, e.g. "2025.7.23-debian-12-r3"
  }))
  default = {}
}
