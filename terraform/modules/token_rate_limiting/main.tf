module "foundry" {
  source            = "../foundry"
  unique_name       = "token-rate-limiting-${var.unique_name}"
  apim_principal_id = var.apim_principal_id
  resource_group_id = var.resource_group_id
  location          = "sweden central"
}

resource "azurerm_cognitive_deployment" "gpt41mini" {
  name                 = "gpt-4.1-mini"
  cognitive_account_id = module.foundry.aifoundry_id
  sku {
    name     = "GlobalStandard"
    capacity = 20
  }
  model {
    name    = "gpt-4.1-mini"
    format  = "OpenAI"
    version = "2025-04-14"
  }
}

module "inference_api" {
  source              = "../inference_api"
  use_case            = "token-rate-limiting"
  display_name        = "Token Rate Limiting Inference API"
  unique_name         = var.unique_name
  api_management_id   = var.api_management_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  policy_xml = replace(
    file("${path.module}/policy.xml"),
    "{backend-id}",
  azapi_resource.backend_inference.name)
  inference_api_type = "openai"
  inference_api_path = "tl-inference"
}

resource "azurerm_api_management_subscription" "inference" {
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  product_id          = azurerm_api_management_product.limited.id
  display_name        = "Token Rate Limiting Inference API"
  state               = "active"
  allow_tracing       = true
}

resource "azapi_resource" "backend_inference" {
  type      = "Microsoft.ApiManagement/service/backends@2024-10-01-preview"
  name      = "token-rate-limiting-backend"
  parent_id = var.api_management_id

  body = {
    properties = {
      protocol    = "http"
      url         = "${module.foundry.aifoundry_endpoint}openai"
      description = "Token Rate Limiting Inference Backend"
      credentials = {
        managedIdentity = {
          resource = "https://cognitiveservices.azure.com"
        }
      }
    }
  }
  schema_validation_enabled = false # because of block 'managedIdentity'
}

resource "azurerm_api_management_product" "limited" {
  product_id            = "token-rate-limiting-product"
  display_name          = "Token Rate Limiting Product"
  api_management_name   = var.api_management_name
  resource_group_name   = var.resource_group_name
  subscription_required = true
  published             = true
}

resource "azurerm_api_management_product_api" "limited_inference_api" {
  product_id          = azurerm_api_management_product.limited.product_id
  api_name            = module.inference_api.inference_api_name
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_product_policy" "limited" {
  product_id          = azurerm_api_management_product.limited.product_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name

  xml_content = file("${path.module}/token_rate_limiting.xml")
}
