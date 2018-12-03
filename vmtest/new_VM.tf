#Query the necessary infos with:
#az account show --query "{subscriptionId:id, tenantId:tenantId}"
#az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"
# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "beaac0ea-1db2-4d68-accb-d490a1f94a05"
  client_id       = "b07ea1bb-f355-4e03-92ca-d0484fd73442"
  client_secret   = "d8306bfe-8c1b-4ec6-a3a7-28ab1c6ea376"
  tenant_id       = "4b6e1e89-f41c-4839-a5dc-b943ec611b97"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "vpngroup" {
    name     = "RG_GW_Test"
    location = "westeurope"
    tags {
        environment = "MSDN Test 2019"
    }
}

# Create a virtual network if it doesn´t exist
resource "azurerm_virtual_network" "vpnnet" {
    name                = "VNet_GW_Test"
    address_space       = ["10.0.0.0/20"]
    location            = "westeurope"
    # Link to ressource group
    resource_group_name = "${azurerm_resource_group.vpngroup.name}"
    tags {
        environment = "MSDN Test 2019"
    }
}

# Create gateway subnet if it doesn´t exist
resource "azurerm_subnet" "gwsub" {
    name                 = "Sub_GW_Test"
    resource_group_name  = "${azurerm_resource_group.vpngroup.name}"
    virtual_network_name = "${azurerm_virtual_network.vpnnet.name}"
    address_prefix       = "10.0.0.0/27"
}

# Create server subnet if it doesn´t exist
resource "azurerm_subnet" "serversub" {
    name                 = "Sub_Server_Test"
    resource_group_name  = "${azurerm_resource_group.vpngroup.name}"
    virtual_network_name = "${azurerm_virtual_network.vpnnet.name}"
    address_prefix       = "10.0.0.32/27"
}

# Create static public ip if it doesn´t exist
resource "azurerm_public_ip" "gwpub" {
    name                         = "PubIP_GW_Test"
    location                     = "westeurope"
    resource_group_name          = "${azurerm_resource_group.vpngroup.name}"
    public_ip_address_allocation = "static"

    tags {
        environment = "MSDN Test 2019"
    }
}

# Local gateway
resource "azurerm_local_network_gateway" "onprem" {
  name                = "VPN_OnPrem_GW"
  location            = "westeurope"
  resource_group_name = "${azurerm_resource_group.vpngroup.name}"
  gateway_address     = "93.135.161.245"
  address_space       = ["192.168.178.0/24"]
}

# Create vpn gateway if it doesn´t exist
resource "azurerm_virtual_network_gateway" "vpngw" {
  name                = "VPN_GW_Test"
  location            = "westeurope"
  resource_group_name = "${azurerm_resource_group.vpngroup.name}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    public_ip_address_id          = "${azurerm_public_ip.gwpub.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.gwsub.id}"
  }
}

resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  name                = "onpremise"
  location            = "westeurope"
  resource_group_name = "${azurerm_resource_group.vpngroup.name}"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vpngw.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.onprem.id}"

  shared_key = "my-vpn-1ps3c-k3y-f0r-4zur3"
}
