variable "unique_name" {
  type        = string
  description = "Unique suffix propagated from root module."
}

variable "apim_principal_id" {
  type        = string
  description = "Principal Id of APIM system-assigned identity used for role assignment."
}

variable "resource_group_id" {
  type        = string
  description = "Resource group id for deployment."
}

variable "location" {
  type        = string
  description = "Azure region for Cognitive Services account."
}

variable "models_config" {
  type = list(object({
    name      = string
    format = string
    version   = string
    sku       = string
    capacity  = number
  }))
  description = "List of model deployments to create inside the Cognitive Services account."
  default = []
}
