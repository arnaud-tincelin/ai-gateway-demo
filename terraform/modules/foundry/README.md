# Foundry Module (Placeholder)

Represents the original `foundryModule` from the Bicep template. It should:
- Provision / reference Azure AI or Cognitive Services resources
- Produce an `extended_ai_services` output (list of objects) containing at least an `endpoint` field

## Expected Variables
- `ai_services_config` (list(any))
- `models_config` (list(any))
- `apim_principal_id` (string)
- `foundry_project_name` (string)

## Expected Outputs
```
output "extended_ai_services" {
  value = [
    {
      endpoint = "https://your-ai-endpoint/"
    }
  ]
}
```

Adapt according to the real architecture.
