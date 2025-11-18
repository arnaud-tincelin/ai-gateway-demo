module "foundry" {
  source            = "../foundry"
  unique_name       = "token-metrics-emitting-${var.unique_name}"
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
  use_case            = "token-metrics-emitting"
  display_name        = "Token Metrics Emitting Inference API"
  unique_name         = var.unique_name
  api_management_id   = var.api_management_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  policy_xml = replace(
    file("${path.module}/token_metrics_emitting.xml"),
    "{backend-id}",
  azapi_resource.backend_inference.name)
  inference_api_type = "openai"
  inference_api_path = "tme-inference"
}

resource "azurerm_api_management_subscription" "inference_1" {
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  display_name        = "All APIS 1"
  state               = "active"
  allow_tracing       = true
}

resource "azurerm_api_management_subscription" "inference_2" {
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  display_name        = "All APIS 2"
  state               = "active"
  allow_tracing       = true
}

resource "azurerm_api_management_subscription" "inference_3" {
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  display_name        = "All APIS 3"
  state               = "active"
  allow_tracing       = true
}

resource "azapi_resource" "backend_inference" {
  type      = "Microsoft.ApiManagement/service/backends@2024-10-01-preview"
  name      = "token-metrics-emitting-backend"
  parent_id = var.api_management_id

  body = {
    properties = {
      protocol    = "http"
      url         = "${module.foundry.aifoundry_endpoint}openai"
      description = "Token Metrics Emitting Inference Backend"
      credentials = {
        managedIdentity = {
          resource = "https://cognitiveservices.azure.com"
        }
      }
    }
  }
  schema_validation_enabled = false # because of block 'managedIdentity'
}

resource "azapi_resource" "api_diagnostics_appinsights" {
  type      = "Microsoft.ApiManagement/service/apis/diagnostics@2024-06-01-preview"
  name      = "applicationinsights"
  parent_id = module.inference_api.inference_api_id

  body = {
    properties = {
      alwaysLog               = "allErrors"
      httpCorrelationProtocol = "W3C"
      logClientIp             = true
      loggerId                = var.apim_logger_id
      metrics                 = true
      verbosity               = "verbose"

      sampling = {
        samplingType = "fixed"
        percentage   = 100
      }

      frontend = {
        request  = { headers = [], body = { bytes = 0 } }
        response = { headers = [], body = { bytes = 0 } }
      }

      backend = {
        request  = { headers = [], body = { bytes = 0 } }
        response = { headers = [], body = { bytes = 0 } }
      }

      largeLanguageModel = {
        logs      = "enabled"
        requests  = { messages = "all", maxSizeInBytes = 262144 }
        responses = { messages = "all", maxSizeInBytes = 262144 }
      }
    }
  }
}
