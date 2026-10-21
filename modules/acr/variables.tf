variable "env_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "aks_kubelet_identity_object_id" {
  type        = string
  description = "Object ID of the AKS kubelet managed identity. Used for the AcrPull role assignment so pods can pull images."
}

variable "tags" {
  type    = map(string)
  default = {}
}
