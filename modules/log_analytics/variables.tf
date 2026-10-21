variable "resource_group_name" {
  description = "Resource group that owns the Log Analytics workspace."
  type        = string
}

variable "region" {
  description = "Azure region for the Log Analytics workspace."
  type        = string
}

variable "name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "solution_plan_map" {
  description = "Log Analytics solutions to install (keyed by solution name → publisher/product)."
  type = map(object({
    product   = string
    publisher = string
  }))
}

variable "tags" {
  description = "Tags applied to the workspace and solutions."
  type        = map(string)
  default     = {}
}
