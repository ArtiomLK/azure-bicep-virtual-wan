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
// vwan
param vwan_n string = 'vwan-${project_n}-${env}-${location}'

// vwan - hub
param vwan_hub_n string = 'vwanhub-${project_n}-${env}-${location}'
param vwan_hub_location string = location
param vwan_hub_addr_prefix string = '10.100.0.0/23'

// vwan - vpng
param vpng_n string = 'vwangw-${project_n}-${env}-${location}'
param vpng_location string = location

// vNet
// param vnetIdP string = ''
// param vnetNameP string = 'vnet-${suffix}'
// param vnetAddrP string = '10.10.0.0/16'

// // sNet - AGW
// param snetAgwNameP string = 'snet-agw-${suffix}'
// param snetAgwAddrP string = '10.10.1.0/24'
// // sNet - AGW - NSG
// param nsgAgwNameP string = 'nsg-agw-${suffix}'

// // sNet - ASE
// param snetAseNameP string = 'snet-ase-${suffix}'
// param snetAseAddrP string = '10.10.2.0/24'

// ------------------------------------------------------------------------------------------------
// VWAN Configuration parameters
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
module vwanhubDeploy 'components/vwan/vhub.bicep' = {
  name: 'vwanhub-${vwan_hub_location}'
  params: {
    vwan_hub_n: vwan_hub_n
    location: vwan_hub_location
    vwan_hub_addr_prefix: vwan_hub_addr_prefix
    vwanId: vwan.outputs.vwanId
  }
}

// VWAN - gw
module vpng 'components/vwan/vpng.bicep' = {
  name: 'vpng'
  params: {
    vpng_n: vpng_n
    vpng_location: vpng_location
    vwanhubId: vwanhubDeploy.outputs.vwanhubId
  }
}

output id string = vwan.outputs.vwanId
