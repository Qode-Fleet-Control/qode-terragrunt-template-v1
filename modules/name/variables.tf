variable "project" {
  description = "Short project name, used as the prefix of every generated name."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "pet_length" {
  description = "Number of words in the generated pet name."
  type        = number
  default     = 2
}
