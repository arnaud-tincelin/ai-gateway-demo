output "inference_api_id" {
  value = module.inference_api.inference_api_id
}

output "inference_api_path" {
  value = module.inference_api.inference_api_path
}

output "inference_api_version" {
  value = module.inference_api.inference_api_version
}

output "product_api_key" {
  value     = azurerm_api_management_subscription.inference.primary_key
  sensitive = true
}

output "deployment_model_name" {
  value = azurerm_cognitive_deployment.gpt41mini.name
}
