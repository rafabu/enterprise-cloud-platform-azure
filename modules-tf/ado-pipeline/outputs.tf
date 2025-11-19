output "yaml_pipelines" {
  description = "core properties of Azure DevOps YAML pipelines created"
  value = {
    for key, val in azuredevops_build_definition.pipelines : key => {
      id         = val.id,
      name       = val.name,
      path       = val.path,
      repository = val.repository
    }
  }
}
