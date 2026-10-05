output "name" {
  description = "Generated name."
  value       = random_pet.this.id
}

output "unique_name" {
  description = "Generated name plus a random hex suffix."
  value       = "${random_pet.this.id}-${random_id.suffix.hex}"
}
