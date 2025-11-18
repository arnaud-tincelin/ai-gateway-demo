output "inference_api_id" {
  value = azurerm_api_management_api.this.id
}

output "inference_api_name" {
  value = azurerm_api_management_api.this.name
}

output "inference_api_path" {
  value = var.inference_api_path
}

output "inference_api_version" {
  value = var.inference_api_type == "openai" ? "2025-03-01-preview" : "2024-05-01-preview" # from specs/azureopenai.json and specs/azureai.json
}
