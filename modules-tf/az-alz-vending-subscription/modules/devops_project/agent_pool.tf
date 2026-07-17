##################################################    Agent Pool (re-use)    ################################################## 
data "azuredevops_agent_pool" "this" {
  name = var.shared_agent_pool_name
}

# assign shared agent pool
resource "azuredevops_agent_queue" "this" {
  project_id    = azuredevops_project.this.id
  agent_pool_id = data.azuredevops_agent_pool.this.id
}

# grant access to agent pool for all pipelines in the project (pre-authorize)
resource "azuredevops_pipeline_authorization" "agent_queue_shared" {
  project_id  = azuredevops_project.this.id
  resource_id = azuredevops_agent_queue.this.id
  type        = "queue"
}
