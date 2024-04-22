terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  version = ">=2.0"
  # The "feature" block is required for AzureRM provider 2.x.
  features {}
}

#resource "azurerm_resource_group" "rg" {
#  name     = "rg-test-tf-tf-uae"
#  location = "uaenorth"
#}


#provider "azurerm" {
#  features {}
#  skip_provider_registration = true  
#}

resource "azurerm_resource_group" "aks" {
  name     = "rg-test-tf-uae"  // Ensure this name is unique before applying
  location = "uaenorth"
}

resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-vnet-test-tf"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet-test-tf"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-test-tf"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "aksterraform"

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_DS2_v2"
    vnet_subnet_id  = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    service_cidr   = "10.0.2.0/24"  // Updated to avoid overlapping with other subnets
    dns_service_ip = "10.0.2.10"    // Ensure it is within the service CIDR range
  }
}
