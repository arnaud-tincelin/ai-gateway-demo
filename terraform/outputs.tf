output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "application_insights_name" {
  value = azapi_resource.application_insights.name
}

output "apim_service_id" { value = azurerm_api_management.this.id }
output "apim_gateway_url" { value = azurerm_api_management.this.gateway_url }

output "rediscache_host" { value = azurerm_managed_redis.this.hostname }
output "rediscache_key" {
  value     = azurerm_managed_redis.this.default_database[0].primary_access_key
  sensitive = true
}
output "rediscache_port" { value = azurerm_managed_redis.this.default_database[0].port }

output "semantic_caching" {
  value = {
    inference_api_id      = module.semantic_caching.inference_api_id
    inference_api_path    = module.semantic_caching.inference_api_path
    inference_api_version = module.semantic_caching.inference_api_version
    inference_api_key     = module.semantic_caching.inference_api_key
  }
  sensitive = true
}

output "load_balancing" {
  value = {
    inference_api_id      = module.load_balancing.inference_api_id
    inference_api_path    = module.load_balancing.inference_api_path
    inference_api_version = module.load_balancing.inference_api_version
    inference_api_key     = module.load_balancing.inference_api_key
    deployment_name       = module.load_balancing.deployment_name
    deployment_model      = module.load_balancing.deployment_model
  }
  sensitive = true
}

output "token_rate_limiting" {
  value = {
    inference_api_id      = module.token_rate_limiting.inference_api_id
    inference_api_path    = module.token_rate_limiting.inference_api_path
    inference_api_version = module.token_rate_limiting.inference_api_version
    product_api_key       = module.token_rate_limiting.product_api_key
    deployment_model_name = module.token_rate_limiting.deployment_model_name
  }
  sensitive = true
}

output "token_metrics_emitting" {
  value = {
    inference_api_id      = module.token_metrics_emitting.inference_api_id
    inference_api_path    = module.token_metrics_emitting.inference_api_path
    inference_api_version = module.token_metrics_emitting.inference_api_version
    all_apis_key_1        = module.token_metrics_emitting.all_apis_key_1
    all_apis_key_2        = module.token_metrics_emitting.all_apis_key_2
    all_apis_key_3        = module.token_metrics_emitting.all_apis_key_3
    deployment_model_name = module.token_metrics_emitting.deployment_model_name
  }
  sensitive = true
}
