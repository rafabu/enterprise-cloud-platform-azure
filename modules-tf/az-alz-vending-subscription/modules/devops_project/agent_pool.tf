##################################################    Agent Pool (re-use)    ##################################################
data "azuredevops_agent_pool" "this" {
  name = var.shared_agent_pool_name
}

# assign shared agent pool
# create an agent queue for the shared agent pool within the project
#     default 'Azure Pipelines' agent pool will already exist

moved {
  from = azuredevops_agent_queue.this
  to   = azuredevops_agent_queue.this["do"]
}
resource "azuredevops_agent_queue" "this" {
  for_each = toset(var.shared_agent_pool_name == "Azure Pipelines" ? [] : ["do"])

  project_id    = azuredevops_project.this.id
  agent_pool_id = data.azuredevops_agent_pool.this.id
}

# grant access to agent pool for all pipelines in the project (pre-authorize)
moved {
  from = azuredevops_pipeline_authorization.agent_queue_shared
  to   = azuredevops_pipeline_authorization.agent_queue_shared["do"]
}
resource "azuredevops_pipeline_authorization" "agent_queue_shared" {
  for_each = toset(var.shared_agent_pool_name == "Azure Pipelines" ? [] : ["do"])

  project_id  = azuredevops_project.this.id
  resource_id = azuredevops_agent_queue.this[each.key].id
  type        = "queue"
}
