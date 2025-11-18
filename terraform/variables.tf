// Single variable to guarantee uniqueness in resource naming.
variable "unique_name" {
  type        = string
  description = "Unique suffix or identifier used in resource names (e.g. mylab01)."
}
