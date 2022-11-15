targetScope = 'resourceGroup'
// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
// Sample tags parameters
var tags = {
  project: 'bicephub'
  env: 'dev'
}

param location string = 'eastus2'

// ------------------------------------------------------------------------------------------------
// VWAN Configuration parameters
// ------------------------------------------------------------------------------------------------
var vwan_n = 'vwan-${tags.project}-${tags.env}-${location}'
param vwan_location string = location

var vhub_locations = ['eastus2', 'centralus', 'eastus', 'westus3']
var vhub_names = [for l in vhub_locations: 'vwanhub-${tags.project}-${tags.env}-${l}']
// express route, vpng, site-to-site, fw
var vhub_addr_prefixes = [for i in range(1, length(vhub_locations)): '${i*50}.0.0.0/24']    // 50.0.0.0/24, 100.0.0.0/24, 150.0.0.0/24, 200.0.0.0/24

// vwan - vpng
// var vpng_enabled = false
var vpng_enabled = [false, false, false, false]
var vpng_names = [for l in vhub_locations: 'vpng-${tags.project}-${tags.env}-${l}']

// ------------------------------------------------------------------------------------------------
// VNETS Configuration parameters
// ------------------------------------------------------------------------------------------------
// custom-hub
var vnet_nva_hub_names = [for l in vhub_locations: 'vnet-nva-hub-${tags.project}-${tags.env}-${l}']
var snet_nva_hub_names = [for l in vhub_locations: 'snet-nva-hub-${l}']
var vnet_nva_hub_prefixes = [for i in range(1, length(vhub_locations)): '${i*50}.0.1.0/24']       // 50.0.1.0/24, 100.0.1.0/24, 150.0.1.0/24, 200.0.1.0/24
var snet_nva_hub_prefixes = [for i in range(1, length(vhub_locations)): '${i*50}.0.1.128/25']     // 50.0.1.128/25, 100.0.1.128/25, 150.0.1.128/25, 200.0.1.128/25

// vnet-spoke-1
var vnet_spoke_1_names = [for l in vhub_locations: 'vnet-spoke-1-${tags.project}-${tags.env}-${l}']
var snet_spoke_1_names = [for l in vhub_locations: 'snet-spoke-1-${l}']
var vnet_spoke_1_prefixes = [for i in range(1, length(vhub_locations)): '${i*50}.0.10.0/24']       // 50.0.10.0/24, 100.0.10.0/24, 150.0.10.0/24, 200.0.10.0/24
var snet_spoke_1_prefixes = [for i in range(1, length(vhub_locations)): '${i*50}.0.10.128/25']     // 50.0.10.128/25, 100.0.10.128/25, 150.0.10.128/25, 200.0.10.128/25

// vnet-spoke-n
var vnet_spoke_n_names = [for l in vhub_locations: 'vnet-spoke-n-${tags.project}-${tags.env}-${l}']
var snet_spoke_n_names = [for l in vhub_locations: 'snet-spoke-n-${l}']
var vnet_spoke_n_prefixes = [for i in range(1, length(vhub_locations)): '${i*50}.0.11.0/24']       // 50.0.11.0/24, 100.0.11.0/24, 150.0.11.0/24, 200.0.11.0/24
var snet_spoke_n_prefixes = [for i in range(1, length(vhub_locations)): '${i*50}.0.11.128/25']     // 50.0.11.128/25, 100.0.11.128/25, 150.0.11.128/25, 200.0.11.128/25

// vnet-connections
var vhub_net_connections_nva_hub = [for i in range(0, length(vhub_locations)): [i, '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnet_nva_hub_names[i]}', vnet_nva_hub_names[i] ]]
var vhub_net_connections_spoke_1 = [for i in range(0, length(vhub_locations)): [i, '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnet_spoke_1_names[i]}', vnet_spoke_1_names[i] ]]
var vhub_net_connections_spoke_n = [for i in range(0, length(vhub_locations)): [i, '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnet_spoke_n_names[i]}', vnet_spoke_n_names[i] ]]

var vhub_net_connections = concat(vhub_net_connections_nva_hub, vhub_net_connections_spoke_1, vhub_net_connections_spoke_n)

// ------------------------------------------------------------------------------------------------
// Bastion Configuration parameters
// ------------------------------------------------------------------------------------------------
var bas_enabled = [true, true, true, true]
var bas_names = [for l in vhub_locations: 'bas-${tags.project}-${tags.env}-${l}']
var bas_pip_names = [for l in vhub_locations: 'bas-pip-${tags.project}-${tags.env}-${l}']
var bas_vnet_names = [for l in vhub_locations: 'vnet-bas-${tags.project}-${tags.env}-${l}']
var bas_vnet_prefixes = [for i in range(1, length(vhub_locations)): '${i*50}.0.2.0/24']
var bas_snet_prefixes = [for i in range(1, length(vhub_locations)): '${i*50}.0.2.0/26']

var snet_bas_ids = [for bas_vnet_n in bas_vnet_names: '${subscription().id}/resourceGroups/${ resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${bas_vnet_n}/subnets/AzureBastionSubnet']

// ------------------------------------------------------------------------------------------------
// VNET - Deploy Custom Hub Vnet for third party NVA
// ------------------------------------------------------------------------------------------------
module vnetNvaHub '../components/vnet/vnet.bicep' = [for i in range(0, length(vnet_nva_hub_names)) :{
  name: vnet_nva_hub_names[i]
  params: {
    vnet_n: vnet_nva_hub_names[i]
    vnet_addr: vnet_nva_hub_prefixes[i]
    subnets: [
      {
        name: snet_nva_hub_names[i]
        subnetPrefix: snet_nva_hub_prefixes[i]
        nsgId: nsgDefault[i].outputs.id
      }
    ]
    defaultNsgId: nsgDefault[i].outputs.id
    location: vhub_locations[i]
    tags: tags
  }
  dependsOn: [
    nsgDefault
  ]
}]

// NSG - Default
module nsgDefault '../components/nsg/nsgDefault.bicep' = [for l in vhub_locations: {
  name: 'nsg-default-${l}'
  params: {
    tags: tags
    location: l
    name: 'nsg-default-${l}'
  }
}]


// ------------------------------------------------------------------------------------------------
// VNET - Deploy Spokes Vnets
// ------------------------------------------------------------------------------------------------
module vnetSpoke1 '../components/vnet/vnet.bicep' = [for i in range(0, length(vnet_spoke_1_names)) :{
  name: vnet_spoke_1_names[i]
  params: {
    vnet_n: vnet_spoke_1_names[i]
    vnet_addr: vnet_spoke_1_prefixes[i]
    subnets: [
      {
        name: snet_spoke_1_names[i]
        subnetPrefix: snet_spoke_1_prefixes[i]
        nsgId: nsgDefault[i].outputs.id
      }
    ]
    defaultNsgId: nsgDefault[i].outputs.id
    location: vhub_locations[i]
    tags: tags
  }
  dependsOn: [
    nsgDefault
  ]
}]

module vnetSpokeN '../components/vnet/vnet.bicep' = [for i in range(0, length(vnet_spoke_n_names)) :{
  name: vnet_spoke_n_names[i]
  params: {
    vnet_n: vnet_spoke_n_names[i]
    vnet_addr: vnet_spoke_n_prefixes[i]
    subnets: [
      {
        name: snet_spoke_n_names[i]
        subnetPrefix: snet_spoke_n_prefixes[i]
        nsgId: nsgDefault[i].outputs.id
      }
    ]
    defaultNsgId: nsgDefault[i].outputs.id
    location: vhub_locations[i]
    tags: tags
  }
  dependsOn: [
    nsgDefault
  ]
}]

// module spoke1vnet '../components/vnet/vnet.bicep' = {
//   name: 'vnet-spoke-1'
//   params: {
//     tags: tags
//     vnet_n: vnet_spoke_1_n
//     vnet_addr: vnet_spoke_1_prefix
//     subnets: [
//       {
//         name: 'snet-spoke-1'
//         subnetPrefix: snet_spoke_1_prefix
//         nsgId: nsgDefaultDeploy.outputs.id
//       }
//     ]
//     defaultNsgId: nsgDefaultDeploy.outputs.id
//     location: location
//   }
// }

// module spoke2vnet '../components/vnet/vnet.bicep' = {
//   name: 'vnet-spoke-2'
//   params: {
//     tags: tags
//     vnet_n: vnet_spoke_2_n
//     vnet_addr: vnet_spoke_2_prefix
//     subnets: [
//       {
//         name: 'snet-spoke-2'
//         subnetPrefix: snet_spoke_2_prefix
//         nsgId: nsgDefaultDeploy.outputs.id
//       }
//     ]
//     defaultNsgId: nsgDefaultDeploy.outputs.id
//     location: location
//   }
// }

// ------------------------------------------------------------------------------------------------
// Bastion - Deploy Azure Bastion
// ------------------------------------------------------------------------------------------------
module bastionVnet '../components/vnet/vnet.bicep' = [for i in range(0, length(vhub_locations)) : if (bas_enabled[i]) {
  name: bas_vnet_names[i]
  params: {
    tags: tags
    vnet_n: bas_enabled[i] ? bas_vnet_names[i] : 'not-enabled'
    vnet_addr: bas_enabled[i] ? bas_vnet_prefixes[i] : 'not-enabled'
    subnets: [
      {
        name: 'AzureBastionSubnet'
        subnetPrefix: bas_enabled[i] ? bas_snet_prefixes[i] : 'not-enabled'
        nsgId: bas_enabled[i] ? nsgBastion[i].outputs.id : 'not-enabled'
      }
    ]
    defaultNsgId: nsgDefault[i].outputs.id
    location: vhub_locations[i]
  }
  dependsOn: [
    nsgBastion
  ]
}]

module nsgBastion '../components/nsg/nsgBas.bicep'  = [for i in range(0, length(vhub_locations)) : if (bas_enabled[i]) {
  name: 'nsg-bas-${vhub_locations[i]}'
  params: {
    nsgName: bas_enabled[i] ? 'nsg-bas-${vhub_locations[i]}' : 'not-enabled'
    tags:tags
    location: vhub_locations[i]
  }
}]

module pipBastion '../components/pip/pip.bicep' = [for i in range(0, length(vhub_locations)) : if (bas_enabled[i]) {
  name: bas_pip_names[i]
  params: {
    pip_n: bas_enabled[i] ? bas_pip_names[i] : 'not-enabled'
    tags: tags
    location: vhub_locations[i]
  }
}]

module bas '../components/bas/bas.bicep' = [for i in range(0, length(vhub_locations)) : if (bas_enabled[i]) {
  name: bas_names[i]
  params: {
    bas_n: bas_enabled[i] ? bas_names[i] : 'not-enabled'
    snet_bas_id: bas_enabled[i] ? snet_bas_ids[i] : 'not-enabled'
    pip_id: bas_enabled[i] ? pipBastion[i].outputs.id : 'not-enabled'
    location: vhub_locations[i]
  }
  dependsOn: [
    bastionVnet
    pipBastion
  ]
}]

// ------------------------------------------------------------------------------------------------
// VWAN Deployment Examples
// ------------------------------------------------------------------------------------------------

module vwanDeployment '../main.bicep' = {
  name: 'vwanDeployment'
  params: {
    location: location

    vwan_n: vwan_n
    vwan_location: vwan_location

    vhub_names: vhub_names
    vhub_locations: vhub_locations
    vhub_addr_prefixes: vhub_addr_prefixes

    vpng_enabled: vpng_enabled
    vpng_names: vpng_names

    vhub_net_connections: vhub_net_connections
  }
}
