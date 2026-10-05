resource "random_pet" "this" {
  length    = var.pet_length
  prefix    = "${var.project}-${var.environment}"
  separator = "-"
}

resource "random_id" "suffix" {
  byte_length = 4

  keepers = {
    pet = random_pet.this.id
  }
}
