variable "name" {
  description = "Name the manifest describes (from the name unit)."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "tags" {
  description = "Tags written into the manifest."
  type        = map(string)
  default     = {}
}
