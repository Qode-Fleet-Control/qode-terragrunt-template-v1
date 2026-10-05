#!/bin/sh
# The job: format checks, then validate and plan every unit under live/ (in DAG order).
# Exits non-zero on the first failure.
set -eu
cd "$(dirname "$0")/.."
echo "==> terragrunt hcl fmt --check";       terragrunt hcl fmt --check --diff
echo "==> terraform fmt -check modules/";    terraform fmt -check -recursive -diff modules
echo "==> terragrunt hcl validate";          terragrunt hcl validate --working-dir live
echo "==> terragrunt run --all validate";    terragrunt run --all --working-dir live -- validate
echo "==> terragrunt run --all plan";        terragrunt run --all --working-dir live -- plan -input=false -lock=false
