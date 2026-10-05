# root.hcl — configuration every unit under live/ includes.
#
# Each unit reads its environment from the nearest env.hcl, keeps its state in a local
# backend under .state/ (no cloud account needed), and gets the common inputs below.
# Replace the generated backend with `remote_state { backend = "s3" ... }` (or gcs, azurerm)
# when the units manage real infrastructure.

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment = local.env_vars.locals.environment
  project     = "fleet"
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOT
terraform {
  backend "local" {
    path = "${get_parent_terragrunt_dir()}/.state/${path_relative_to_include()}/terraform.tfstate"
  }
}
EOT
}

inputs = {
  project     = local.project
  environment = local.environment
  tags = {
    project     = local.project
    environment = local.environment
    managed_by  = "terragrunt"
  }
}
