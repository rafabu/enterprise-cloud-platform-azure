module "entra_id_permissions" {
  source = "./modules/role_permission_pair"

  role_display_name          = "role-testing"
  role_eligible_display_name = "role-testing-eligible"
  permission_display_name    = "permission-testing"
  role_member_object_ids = [
    "86984e3c-69ef-4cf0-9c37-3c5e940408cd", # Raphael Burri (guest user)
    "c17ad8e5-871f-4d00-a6c1-c4b7841dd573", # Lukas Rottach (guest user)
    "678326f7-78a8-4916-83e8-5671ef662b94", # Cédric Mendelin (guest user)
    "27adb7f0-20f5-47aa-b0a6-7f8996b0058f"  # Sebastian Ebner (guest users)
  ]
  use_pim = true
  pim_permanent_role_member_object_ids = [
    data.azapi_client_config.current.object_id
  ]
}
