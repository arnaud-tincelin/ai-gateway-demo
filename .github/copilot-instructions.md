## Follow Terraform best practices

Terraform treats any local directory referenced in the source argument of a module block as a module. A typical file structure for a new module is:

```
.
├── LICENSE
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
```

None of these files are required, or have any special meaning to Terraform when it uses your module. You can create a module with a single .tf file, or use any other file structure you like.

Each of these files serves a purpose:

- `LICENSE` will contain the license under which your module will be distributed. When you share your module, the LICENSE file will let people using it know the terms under which it has been made available. Terraform itself does not use this file.
- `README.md` will contain documentation describing how to use your module, in markdown format. Terraform does not use this file, but services like the Terraform Registry and GitHub will display the contents of this file to people who visit your module's Terraform Registry or GitHub page.
- `main.tf` will contain the main set of configuration for your module. You can also create other configuration files and organize them however makes sense for your project.
- `variables.tf` will contain the variable definitions for your module. When your module is used by others, the variables will be configured as arguments in the module block. Since all Terraform values must be defined, any variables that are not given a default value will become required arguments. Variables with default values can also be provided as module arguments, overriding the default value.
- `outputs.tf` will contain the output definitions for your module. Module outputs are made available to the configuration using the module, so they are often used to pass information about the parts of your infrastructure defined by the module to other parts of your configuration.


## Providers

Use `azurerm` provider as much as possible and `azapi` provider if a resource is not yet supported in `azurerm`.
`random` provider is forbidden
When working on new implementations, use the latest versions of the providers.
