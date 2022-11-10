targetScope = 'resourceGroup'
// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
param location string = resourceGroup().location

param project_n string = 'topology'
param env string = 'prod'
param tags object = {
  project : project_n
  env: env
}

// ------------------------------------------------------------------------------------------------
// VWAN Configuration parameters
// ------------------------------------------------------------------------------------------------
param vwan_n string = 'vwan-${project_n}-${env}-${location}'

// vwan - hub
param vwan_hub_n string = 'vwanhub-${project_n}-${env}-${location}'
param vwan_hub_location string = location
param vwan_hub_addr_prefix string = '10.100.0.0/23'

// vwan - vpng
param vpng_enabled bool = true
param vpng_n string = 'vwangw-${project_n}-${env}-${location}'
param vpng_location string = location

// ------------------------------------------------------------------------------------------------
// VNETS Configuration parameters
// ------------------------------------------------------------------------------------------------
// custom-hub
param vnet_hub_n string = 'vnet-hub-custom-${project_n}-${env}-${location}'
param vnet_hub_prefix string = '50.50.40.0/23'
param snet_hub_prefix string = '50.50.40.0/24'

// vnet-spoke-1
param vnet_spoke_1_n string = 'vnet-spoke-1-${project_n}-${env}-${location}'
param vnet_spoke_1_prefix string = '50.50.50.0/23'
param snet_spoke_1_prefix string = '50.50.50.0/24'

// vnet-spoke-2
param vnet_spoke_2_n string = 'vnet-spoke-1-${project_n}-${env}-${location}'
param vnet_spoke_2_prefix string = '50.50.60.0/23'
param snet_spoke_2_prefix string = '50.50.60.0/24'

// vnet-bastion
param bas_n string = 'bas-${project_n}-${env}-${location}'
param bas_pip_n string = 'bas-pip-${project_n}-${env}-${location}'
param bas_vnet_n string = 'vnet-bastion-${project_n}-${env}-${location}'
param bas_vnet_prefix string = '50.50.70.0/24'
param bas_snet_prefix string = '50.50.70.0/24'
var bas_nsg_n = 'nsg-bas-${project_n}-${env}-${location}'
var snet_bas_id = '${subscription().id}/resourceGroups/${ resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${bas_vnet_n}/subnets/AzureBastionSubnet'

// ------------------------------------------------------------------------------------------------
// Deploy Custom Hub Vnet
// ------------------------------------------------------------------------------------------------
module hubCustom 'components/vnet/vnet.bicep' = {
  name: 'hubCustomDeployment'
  params: {
    tags: tags
    vnet_n: vnet_hub_n
    vnet_addr: vnet_hub_prefix
    subnets: [
      {
        name: 'snet-hub-custom'
        subnetPrefix: snet_hub_prefix
        nsgId: nsgDefaultDeploy.outputs.id
      }
    ]
    defaultNsgId: nsgDefaultDeploy.outputs.id
    location: location
  }
}

// NSG - Default
module nsgDefaultDeploy 'components/nsg/nsgDefault.bicep' = {
  name: 'nsg-default-deployment'
  params: {
    tags: tags
    location: location
  }
}

// ------------------------------------------------------------------------------------------------
// Deploy Spokes Vnets
// ------------------------------------------------------------------------------------------------
module spoke1vnet 'components/vnet/vnet.bicep' = {
  name: 'vnet-spoke-1'
  params: {
    tags: tags
    vnet_n: vnet_spoke_1_n
    vnet_addr: vnet_spoke_1_prefix
    subnets: [
      {
        name: 'snet-spoke-1'
        subnetPrefix: snet_spoke_1_prefix
        nsgId: nsgDefaultDeploy.outputs.id
      }
    ]
    defaultNsgId: nsgDefaultDeploy.outputs.id
    location: location
  }
}

module spoke2vnet 'components/vnet/vnet.bicep' = {
  name: 'vnet-spoke-2'
  params: {
    tags: tags
    vnet_n: vnet_spoke_2_n
    vnet_addr: vnet_spoke_2_prefix
    subnets: [
      {
        name: 'snet-spoke-1'
        subnetPrefix: snet_spoke_2_prefix
        nsgId: nsgDefaultDeploy.outputs.id
      }
    ]
    defaultNsgId: nsgDefaultDeploy.outputs.id
    location: location
  }
}

// ------------------------------------------------------------------------------------------------
// Deploy Azure Bastion
// ------------------------------------------------------------------------------------------------
module bastionVnet 'components/vnet/vnet.bicep' = {
  name: 'mainVnetDeployment'
  params: {
    tags: tags
    vnet_n: bas_vnet_n
    vnet_addr: bas_vnet_prefix
    subnets: [
      {
        name: 'AzureBastionSubnet'
        subnetPrefix: bas_snet_prefix
        nsgId: nsgBastionDeploy.outputs.id
      }
    ]
    defaultNsgId: nsgDefaultDeploy.outputs.id
    location: location
  }
}

module nsgBastionDeploy 'components/nsg/nsgBas.bicep' = {
  name: 'nsg-bastion'
  params: {
    nsgName: bas_nsg_n
    tags:tags
    location: location
  }
}

module pip 'components/pip/pip.bicep' = {
  name: 'pipDeployment'
  params: {
    pip_n: bas_pip_n
    tags: tags
    location: location
  }
}

module basDeploy 'components/bas/bas.bicep' = {
  name: 'basDeploymet'
  params: {
    bas_n: bas_n
    snet_bas_id: snet_bas_id
    pip_id: pip.outputs.id
    location: location
  }
  dependsOn: [
    bastionVnet
  ]
}

// ------------------------------------------------------------------------------------------------
// VWAN
// ------------------------------------------------------------------------------------------------
module vwan 'components/vwan/vwan.bicep' = {
  name: 'vwan'
  params: {
    vwan_n: vwan_n
    location: location
    tags: tags
  }
}

// VWAN - hub
resource vwanhubDeploy 'Microsoft.Network/virtualHubs@2021-02-01' = {
  name: vwan_hub_n
  location: location
  properties: {
    virtualWan: {
      id: vwan.outputs.vwanId
    }
    addressPrefix: vwan_hub_addr_prefix
  }
  tags: tags
}

// VWAN - gw
module vpng 'components/vwan/vpng.bicep' = if (vpng_enabled) {
  name: 'vpng'
  params: {
    vpng_n: vpng_n
    vpng_location: vpng_location
    vwanhubId: vwanhubDeploy.id
  }
}

// Deploy vNet peerings
resource VwanHub_to_vnet 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
  parent: vwanhubDeploy
  name: 'vwan-to-spoke-1'
  properties: {
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vwan_hub_n, 'defaultRouteTable')
      }
      propagatedRouteTables: {
        labels: [
          'default'
        ]
        ids: [
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vwan_hub_n, 'defaultRouteTable')
          }
        ]
      }
    }
    remoteVirtualNetwork: {
      id: spoke1vnet.outputs.id
    }
    enableInternetSecurity: true
  }
}

output id string = vwan.outputs.vwanId