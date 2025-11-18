variable "display_name" { type = string }
variable "use_case" { type = string }
variable "unique_name" { type = string }
variable "api_management_name" { type = string }
variable "api_management_id" { type = string }
variable "resource_group_name" { type = string }
variable "policy_xml" { type = string }
variable "inference_api_type" {
  type    = string
  default = "openai"
  validation {
    condition     = contains(["openai", "azureai"], var.inference_api_type)
    error_message = "Valid values are: 'openai', 'azureai'"
  }
}
variable "inference_api_path" {
  type    = string
  default = "inference"
}
