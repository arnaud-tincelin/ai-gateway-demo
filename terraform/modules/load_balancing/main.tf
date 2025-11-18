locals {
  deployment_name = "gpt-4o-mini"
  deployment_model = {
    name    = "gpt-4o-mini"
    format  = "OpenAI"
    version = "2024-07-18"
  }
}

module "inference_api" {
  source              = "../inference_api"
  use_case            = "load-balancing"
  display_name        = "Load Balancing Inference API"
  unique_name         = var.unique_name
  api_management_id   = var.api_management_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  policy_xml = replace(
      file("${path.module}/load_balancing.xml"),
      "{backend-id}",
      azapi_resource.apim_backend_pool_openai.name)
  inference_api_type = "openai"
  inference_api_path = "lb-inference"
}

resource "azurerm_api_management_subscription" "inference" {
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  # api_id              = module.inference_api.inference_api_id
  display_name        = "Load Balancing Inference API"
  state               = "active"
  allow_tracing       = true
}

resource "azapi_resource" "apim_backend_pool_openai" {
  type                      = "Microsoft.ApiManagement/service/backends@2024-10-01-preview"
  name                      = "apim-backend-pool"
  parent_id                 = var.api_management_id
  schema_validation_enabled = false

  body = {
    properties = {
      description = "Load balancer for multiple inference endpoints"
      type        = "Pool"

      pool = {
        services = [
          {
            id       = azapi_resource.apim_backend_frc.id
            priority = 1
            weight   = 100
          },
          {
            id       = azapi_resource.apim_backend_uks.id
            priority = 2
            weight   = 50
          },
          {
            id       = azapi_resource.apim_backend_swc.id
            priority = 2
            weight   = 50
          }
        ]
      }
    }
  }
}
