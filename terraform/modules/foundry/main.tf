data "azurerm_client_config" "current" {}

resource "azapi_resource" "aifoundry_project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = "poc-apim"
  parent_id = azapi_resource.aifoundry.id
  location  = var.location
  body = {
    properties = {}
    identity = {
      type = "SystemAssigned"
    }
  }
  schema_validation_enabled = false
  depends_on                = [azurerm_role_assignment.current_user_is_ai_project_manager]
}

resource "azapi_resource" "aifoundry" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = "ai-${var.unique_name}"
  parent_id = var.resource_group_id
  location  = var.location
  body = {
    kind = "AIServices"
    sku  = { name = "S0" }
    properties = {
      publicNetworkAccess    = "Enabled"
      allowProjectManagement = true
      customSubDomainName    = "ai-${var.unique_name}"
      disableLocalAuth       = true
    }
    identity = {
      type = "SystemAssigned"
    }
  }
  response_export_values    = ["properties.endpoint"]
  schema_validation_enabled = false
}

resource "azurerm_role_assignment" "current_user_is_ai_project_manager" {
  scope                = azapi_resource.aifoundry.id
  role_definition_name = "Azure AI Project Manager"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "apim_can_use_cognitive_services" {
  scope                = azapi_resource.aifoundry.id
  role_definition_name = "Cognitive Services User"
  principal_id         = var.apim_principal_id
  principal_type       = "ServicePrincipal"
}

# {
#             "type": "Microsoft.CognitiveServices/accounts/connections",
#             "apiVersion": "2025-06-01",
#             "name": "[concat(parameters('accounts_pfi_foundry_kuqbpx2jmxkuc_name'), '/appInsights-connection-0997')]",
#             "dependsOn": [
#                 "[resourceId('Microsoft.CognitiveServices/accounts', parameters('accounts_pfi_foundry_kuqbpx2jmxkuc_name'))]"
#             ],
#             "properties": {
#                 "authType": "ApiKey",
#                 "category": "AppInsights",
#                 "target": "[parameters('components_pfi_appi_kuqbpx2jmxkuc_externalid')]",
#                 "useWorkspaceManagedIdentity": false,
#                 "isSharedToAll": false,
#                 "sharedUserList": [],
#                 "peRequirement": "NotRequired",
#                 "peStatus": "NotApplicable",
#                 "metadata": {
#                     "ApiType": "Azure",
#                     "ResourceId": "[parameters('components_pfi_appi_kuqbpx2jmxkuc_externalid')]"
#                 }
#             }
#         }
