module "foundry" {
  source            = "../foundry"
  unique_name       = "semantic-${var.unique_name}"
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

resource "azurerm_cognitive_deployment" "txtembed3small" {
  name                 = "text-embedding-3-small"
  cognitive_account_id = module.foundry.aifoundry_id
  sku {
    name     = "GlobalStandard"
    capacity = 20
  }
  model {
    name    = "text-embedding-3-small"
    format  = "OpenAI"
    version = "1"
  }
  depends_on = [
    azurerm_cognitive_deployment.gpt41mini # Another operation is being performed on the parent resource
  ]
}

module "inference_api" {
  source              = "../inference_api"
  use_case            = "semantic-caching"
  display_name        = "Semantic Caching Inference API"
  unique_name         = var.unique_name
  api_management_id   = var.api_management_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  policy_xml = replace(
    replace(
      file("${path.module}/semantic_caching.xml"),
      "{backend-id}",
    azapi_resource.backend_inference.name),
    "{embeddings-backend-id}",
  azapi_resource.backend_embeddings.name)
  inference_api_type = "openai"
  inference_api_path = "sc-inference"
}

resource "azurerm_api_management_subscription" "inference" {
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  # api_id              = module.inference_api.inference_api_id
  display_name        = "Semantic Caching Inference API"
  state               = "active"
  allow_tracing       = true
}

resource "azapi_resource" "backend_inference" {
  type      = "Microsoft.ApiManagement/service/backends@2024-10-01-preview"
  name      = "semantic-caching-backend"
  parent_id = var.api_management_id

  body = {
    properties = {
      protocol    = "http"
      url         = "${module.foundry.aifoundry_endpoint}openai"
      description = "Semantic Caching Inference Backend"
      credentials = {
        managedIdentity = {
          resource = "https://cognitiveservices.azure.com"
        }
      }
    }
  }
  schema_validation_enabled = false # because of block 'managedIdentity'
}

# # Does not support managed identity authentication for now
# resource "azurerm_api_management_backend" "embeddings" {
# }

resource "azapi_resource" "backend_embeddings" {
  type      = "Microsoft.ApiManagement/service/backends@2024-10-01-preview"
  name      = "embeddings-backend"
  parent_id = var.api_management_id

  body = {
    properties = {
      protocol    = "http"
      url         = "${module.foundry.aifoundry_endpoint}openai/deployments/${azurerm_cognitive_deployment.txtembed3small.name}/embeddings"
      description = "Embeddings Backend"
      credentials = {
        managedIdentity = {
          resource = "https://cognitiveservices.azure.com"
        }
      }
    }
  }
  schema_validation_enabled = false # because of block 'managedIdentity'
}
