resource "azurerm_resource_group" "this" {
  name     = "poc-genai-gateway-${var.unique_name}"
  location = "sweden central"
}

resource "azurerm_managed_redis" "this" {
  name                = "redis-${var.unique_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku_name            = "Balanced_B0"

  default_database {
    eviction_policy   = "NoEviction" # Required when using RediSearch module
    clustering_policy = "EnterpriseCluster"
    # https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-cache-external#prerequisites
    # Azure API Management uses a Redis connection string to connect to the cache.
    # If you use Azure Managed Redis, enable access key authentication in your cache to use a connection string.
    # Currently, you can't use Microsoft Entra authentication to connect Azure API Management to Azure Managed Redis.
    access_keys_authentication_enabled = true
    module {
      name = "RediSearch"
    }
  }
}
resource "azurerm_api_management" "this" {
  name                = "apim-${var.unique_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  publisher_name      = "publisher"
  publisher_email     = "publisher@example.com"
  sku_name            = "BasicV2_1"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_monitor_diagnostic_setting" "apim_diagnostics" {
  name                       = "default"
  target_resource_id         = azurerm_api_management.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category_group = "AllLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_api_management_redis_cache" "default" {
  name              = "Default"
  api_management_id = azurerm_api_management.this.id
  # <cache-name>:10000,password=<cache-access-key>,ssl=True,abortConnect=False
  connection_string = "${azurerm_managed_redis.this.hostname}:${azurerm_managed_redis.this.default_database[0].port},password=${azurerm_managed_redis.this.default_database[0].primary_access_key},ssl=True,abortConnect=False"
  redis_cache_id    = azurerm_managed_redis.this.id
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.unique_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sku               = "PerGB2018"
  retention_in_days = 30

  identity {
    type = "SystemAssigned"
  }
}

resource "azapi_resource" "application_insights" {
  type      = "Microsoft.Insights/components@2020-02-02"
  name      = "insights-${var.unique_name}"
  location  = azurerm_resource_group.this.location
  parent_id = azurerm_resource_group.this.id

  body = {
    kind = "web"
    properties = {
      Application_Type         = "web"
      WorkspaceResourceId      = azurerm_log_analytics_workspace.this.id
      CustomMetricsOptedInType = "WithDimensions"
    }
  }

  schema_validation_enabled = false # because of property 'CustomMetricsOptedInType'
}

resource "azapi_resource" "apim_logger" {
  type      = "Microsoft.ApiManagement/service/loggers@2024-10-01-preview"
  name      = "apim"
  parent_id = azurerm_api_management.this.id

  body = {
    properties = {
      credentials = {
        instrumentationKey = azapi_resource.application_insights.output.properties.InstrumentationKey
      }
      description = ""
      isBuffered  = true
      loggerType  = "applicationInsights"
    }
  }
}

module "semantic_caching" {
  source              = "./modules/semantic_caching"
  unique_name         = var.unique_name
  api_management_id   = azurerm_api_management.this.id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  resource_group_id   = azurerm_resource_group.this.id
  apim_principal_id   = azurerm_api_management.this.identity[0].principal_id
}

module "load_balancing" {
  source              = "./modules/load_balancing"
  unique_name         = var.unique_name
  api_management_id   = azurerm_api_management.this.id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  resource_group_id   = azurerm_resource_group.this.id
  apim_principal_id   = azurerm_api_management.this.identity[0].principal_id

  depends_on = [module.semantic_caching] # Avoid parallel updates to APIM
}

module "token_rate_limiting" {
  source              = "./modules/token_rate_limiting"
  unique_name         = var.unique_name
  api_management_id   = azurerm_api_management.this.id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  resource_group_id   = azurerm_resource_group.this.id
  apim_principal_id   = azurerm_api_management.this.identity[0].principal_id

  depends_on = [module.load_balancing] # Avoid parallel updates to APIM
}

module "token_metrics_emitting" {
  source              = "./modules/token_metrics_emitting"
  unique_name         = var.unique_name
  api_management_id   = azurerm_api_management.this.id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  resource_group_id   = azurerm_resource_group.this.id
  apim_principal_id   = azurerm_api_management.this.identity[0].principal_id
  apim_logger_id      = azapi_resource.apim_logger.id

  depends_on = [module.token_rate_limiting] # Avoid parallel updates to APIM
}
