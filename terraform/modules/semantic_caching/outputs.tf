output "inference_api_id" {
  value = module.inference_api.inference_api_id
}

output "inference_api_path" {
  value = module.inference_api.inference_api_path
}

output "inference_api_version" {
  value = module.inference_api.inference_api_version
}

output "inference_api_key" {
  value  = azurerm_api_management_subscription.inference.primary_key
  sensitive = true
}
