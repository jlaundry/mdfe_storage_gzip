
variable "azure_location" {
  type = string
  default = "australiaeast"
}

variable "env" {
  type = string
  default = "prod"
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
  name     = "rg-mdfe-telemetry-${var.env}-${var.azure_location}"
  location = var.azure_location

  tags = var.tags
}

resource "random_id" "mdfetelemetry" {
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

resource "azurerm_storage_container" "archive" {
  name                  = "archive"
  storage_account_name  = azurerm_storage_account.mdfetelemetry.name
  container_access_type = "private"
}

resource "azurerm_management_lock" "mdfetelemetry-lock" {
  name       = "nodelete"
  scope      = azurerm_storage_account.mdfetelemetry.id
  lock_level = "CanNotDelete"
}

output "mdfetelemetry" {
  value = azurerm_storage_account.mdfetelemetry.id
  description = "Data export location for MDfE configuration"
}

module "mdfetelemetryfunc" {
  source                   = "github.com/jlaundry/terraform-azure-library/func"

  name                     = "mdfetelemetry"
  env                      = var.env
  resource_group_name      = azurerm_resource_group.mdfetelemetry.name
  location                 = azurerm_resource_group.mdfetelemetry.location

  tags = azurerm_resource_group.mdfetelemetry.tags
}
