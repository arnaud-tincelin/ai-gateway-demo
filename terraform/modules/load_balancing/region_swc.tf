module "foundry_swc" {
  source            = "../foundry"
  unique_name       = "lb-swc-${var.unique_name}"
  apim_principal_id = var.apim_principal_id
  resource_group_id = var.resource_group_id
  location          = "sweden central"
}

resource "azurerm_cognitive_deployment" "swc" {
  name                 = local.deployment_name
  cognitive_account_id = module.foundry_swc.aifoundry_id
  sku {
    name     = "GlobalStandard"
    capacity = 1
  }
  model {
    name    = local.deployment_model.name
    format  = local.deployment_model.format
    version = local.deployment_model.version
  }
}

resource "azapi_resource" "apim_backend_swc" {
  type                      = "Microsoft.ApiManagement/service/backends@2024-10-01-preview"
  parent_id                 = var.api_management_id
  name                      = "backend-swc"
  schema_validation_enabled = false # Because of managedIdentity block

  body = {
    properties = {
      url         = "${module.foundry_swc.aifoundry_endpoint}openai"
      protocol    = "http"
      description = "Inference backend SWC"

      credentials = {
        managedIdentity = {
          resource = "https://cognitiveservices.azure.com"
        }
      }

      circuitBreaker = {
        rules = [
          {
            failureCondition = {
              count = 1
              errorReasons = [
                "Server errors"
              ]
              interval = "PT5M"
              statusCodeRanges = [
                {
                  min = 429
                  max = 429
                }
              ]
            }
            name             = "InferenceBreakerRule"
            tripDuration     = "PT1M"
            acceptRetryAfter = true // respects the Retry-After header
          }
        ]
      }
    }
  }
}
