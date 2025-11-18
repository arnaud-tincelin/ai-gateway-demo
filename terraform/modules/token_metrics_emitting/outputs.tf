output "inference_api_id" {
  value = module.inference_api.inference_api_id
}

output "inference_api_path" {
  value = module.inference_api.inference_api_path
}

output "inference_api_version" {
  value = module.inference_api.inference_api_version
}

output "all_apis_key_1" {
  value     = azurerm_api_management_subscription.inference_1.primary_key
  sensitive = true
}

output "all_apis_key_2" {
  value     = azurerm_api_management_subscription.inference_2.primary_key
  sensitive = true
}

output "all_apis_key_3" {
  value     = azurerm_api_management_subscription.inference_3.primary_key
  sensitive = true
}

output "deployment_model_name" {
  value = azurerm_cognitive_deployment.gpt41mini.name
}
