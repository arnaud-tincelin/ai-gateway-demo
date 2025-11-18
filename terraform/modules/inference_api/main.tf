resource "azurerm_api_management_api" "this" {
  name                  = var.use_case
  resource_group_name   = var.resource_group_name
  api_management_name   = var.api_management_name
  revision              = "1"
  display_name          = var.display_name
  path                  = "${var.inference_api_path}/${var.inference_api_type}"
  protocols             = ["https"]
  subscription_required = true
  api_type              = "http"

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("${path.module}/specs/${var.inference_api_type == "openai" ? "azureopenai.json" : "azureai.json"}")
  }
}

resource "azurerm_api_management_api_policy" "api_policy" {
  api_name            = azurerm_api_management_api.this.name
  resource_group_name = var.resource_group_name
  api_management_name = var.api_management_name
  xml_content         = var.policy_xml
}
