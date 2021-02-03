
variable "env" {
  type = map(string)
  default = {
    location = "Australia East"
    environment = "Production"
    shortcode = "aepr"
  }
}

variable "tags" {
  type = map(string)
  default = {
      Department = "Security"
      Environment = "Production"
      ServiceOwner = "Jed Laundry"
      TechnicalOwner = "Jed Laundry"
  }
}

resource "azurerm_resource_group" "mdfetelemetry" {
  name     = "rg-${var.env.shortcode}-mdfe-telemetry"
  location = var.env.location

  tags = var.tags
}

resource "random_id" "mdfetelemetry" {
  byte_length = 4
}

resource "random_id" "mdfetelemetryfunc" {
  byte_length = 4
}

resource "azurerm_storage_account" "mdfetelemetry" {
  name                     = "stmdfetelemetry${random_id.mdfetelemetry.hex}"
  resource_group_name      = azurerm_resource_group.mdfetelemetry.name
  location                 = azurerm_resource_group.mdfetelemetry.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  min_tls_version = "TLS1_2"
  allow_blob_public_access = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = azurerm_resource_group.mdfetelemetry.tags
}

output "mdfetelemetry" {
  value = azurerm_storage_account.mdfetelemetry.id
  description = "Data export location for MDfE configuration"
}

# Dedicated storage account for Function-related logs etc.
resource "azurerm_storage_account" "mdfetelemetryfunc" {
  name                     = "stmdfetelemfunc${random_id.mdfetelemetryfunc.hex}"
  resource_group_name      = azurerm_resource_group.mdfetelemetry.name
  location                 = azurerm_resource_group.mdfetelemetry.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"
  allow_blob_public_access = false

  tags = azurerm_resource_group.mdfetelemetry.tags
}

resource "azurerm_app_service_plan" "mdfetelemetryfunc" {
  name                = "asp-${var.env.shortcode}-mdfe-telemetry-${random_id.mdfetelemetryfunc.hex}"
  location            = azurerm_resource_group.mdfetelemetry.location
  resource_group_name = azurerm_resource_group.mdfetelemetry.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  tags = azurerm_resource_group.mdfetelemetry.tags
}

resource "azurerm_application_insights" "mdfetelemetryfunc" {
  name                = "appi-${var.env.shortcode}-mdfe-telemetry-${random_id.mdfetelemetryfunc.hex}"
  location            = azurerm_resource_group.mdfetelemetry.location
  resource_group_name = azurerm_resource_group.mdfetelemetry.name
  application_type    = "web"

  retention_in_days   = 90

  tags = azurerm_resource_group.mdfetelemetry.tags
}

resource "azurerm_function_app" "mdfetelemetryfunc" {
  name                       = "func-${var.env.shortcode}-mdfe-telemetry-${random_id.mdfetelemetryfunc.hex}"
  location                   = azurerm_resource_group.mdfetelemetry.location
  resource_group_name        = azurerm_resource_group.mdfetelemetry.name
  app_service_plan_id        = azurerm_app_service_plan.mdfetelemetryfunc.id
  storage_account_name       = azurerm_storage_account.mdfetelemetryfunc.name
  storage_account_access_key = azurerm_storage_account.mdfetelemetryfunc.primary_access_key

  version                    = "~3"
  os_type                    = "linux"

  app_settings = {
    "AzureWebJobsStorage" = azurerm_storage_account.mdfetelemetryfunc.primary_blob_connection_string
    "MDfETelemetryStorage" = azurerm_storage_account.mdfetelemetry.primary_blob_connection_string
    # "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.mdfetelemetryfunc.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.mdfetelemetryfunc.connection_string
  }

  site_config {
    linux_fx_version  = "Python|3.8"
    ftps_state        = "Disabled"
  }

  # source_control {
  #   repo_url          = "https://github.com/jlaundry/mdfe_storage_gzip.git"
  #   branch            = "main"
  # }

  tags = azurerm_resource_group.mdfetelemetry.tags
}
