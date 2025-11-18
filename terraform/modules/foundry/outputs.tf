output "aifoundry_name" {
  value = azapi_resource.aifoundry.name
}

output "aifoundry_id" {
  value = azapi_resource.aifoundry.id
}

output "aifoundry_endpoint" {
  value = azapi_resource.aifoundry.output.properties.endpoint
}
