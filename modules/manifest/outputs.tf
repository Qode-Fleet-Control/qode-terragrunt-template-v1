output "manifest_path" {
  description = "Where the manifest is written on apply."
  value       = local_file.manifest.filename
}
