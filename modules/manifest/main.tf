resource "null_resource" "announce" {
  triggers = {
    name = var.name
  }
}

resource "local_file" "manifest" {
  filename        = "${path.root}/out/${var.environment}.json"
  file_permission = "0644"
  content = jsonencode({
    name        = var.name
    environment = var.environment
    tags        = var.tags
  })
}
