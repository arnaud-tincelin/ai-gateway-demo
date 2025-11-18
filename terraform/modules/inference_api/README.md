# Inference API Module (Placeholder)

Represents the `inferenceAPIModule` from the original Bicep.

Should:
- Create one or more APIs in API Management
- Attach a policy (contents of `policy.xml` from the original Bicep)
- Use the provided AI services configuration

## Possible Variables
- `policy_xml` (string): XML policy content
- `ai_services_config` (list(any))
- `inference_api_type` (string)
- `inference_api_path` (string)

## Example Outputs
```
output "api_id" { value = azurerm_api_management_api.inference.id }
```

Create resources `azurerm_api_management_api`, `azurerm_api_management_api_operation`, and attach policies via `azurerm_api_management_api_policy`.
