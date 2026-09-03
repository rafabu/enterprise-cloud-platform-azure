# Provider registration is now handled by azurerm 5.x with specific configuration in launchpad-main
removed {
  from = time_sleep.wait_after_provider_register
  lifecycle {
    destroy = false
  }
}
