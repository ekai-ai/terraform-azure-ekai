variable "region" {
  description = "Azure region for the VNet and its subnets."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that owns the VNet."
  type        = string
}

variable "cluster_name" {
  description = "Cluster name used as the base for VNet and subnet names."
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the VNet (e.g. 10.0.0.0/16)."
  type        = string
}

variable "pub_sub_1_a_cidr" {
  description = "CIDR block for the public subnet (NAT gateway, ingress)."
  type        = string
}

variable "pri_sub_1_cidr" {
  description = "CIDR block for private subnet 1 (AKS node pool)."
  type        = string
}

variable "pri_sub_2_cidr" {
  description = "CIDR block for private subnet 2 (PostgreSQL delegated subnet)."
  type        = string
}

variable "pri_sub_3_cidr" {
  description = "CIDR block for private subnet 3 (reserved for future data-plane resources)."
  type        = string
}

variable "tags" {
  description = "Tags applied to the VNet and subnets."
  type        = map(string)
  default     = {}
}
