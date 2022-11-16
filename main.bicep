targetScope = 'resourceGroup'
// ------------------------------------------------------------------------------------------------
// Deployment parameters
// ------------------------------------------------------------------------------------------------
param tags object = {}

// ------------------------------------------------------------------------------------------------
// VWAN Configuration parameters
// ------------------------------------------------------------------------------------------------
param vwan_n string
param vwan_location string = resourceGroup().location

// vwan - hub
param vhub_names array
param vhub_locations array
param vhub_addr_prefixes array

// vwan - vpng
param vpng_enabled array
param vpng_names array

// ------------------------------------------------------------------------------------------------
// VNETS Configuration parameters
// ------------------------------------------------------------------------------------------------
param vhub_net_connections array

// ------------------------------------------------------------------------------------------------
// VWAN
// ------------------------------------------------------------------------------------------------
module vwan 'components/vwan/vwan.bicep' = {
  name: 'vwan'
  params: {
    vwan_n: vwan_n
    location: vwan_location
    tags: tags
  }
}

// ------------------------------------------------------------------------------------------------
// VWAN HUBs
// ------------------------------------------------------------------------------------------------
resource vhub 'Microsoft.Network/virtualHubs@2021-02-01'  = [for i in range(0, length(vhub_locations)) : {
  name: vhub_names[i]
  location: vhub_locations[i]
  properties: {
    virtualWan: {
      id: vwan.outputs.vwanId
    }
    addressPrefix: vhub_addr_prefixes[i]
  }
  tags: tags
}]

// ------------------------------------------------------------------------------------------------
// VWAN VPNG
// ------------------------------------------------------------------------------------------------
module vpng 'components/vwan/vpng.bicep' = [for i in range(0, length(vhub_locations)) : if(vpng_enabled[i]) {
  name: vpng_names[i]
  params: {
    vpng_n: vpng_names[i]
    vpng_location: vhub_locations[i]
    vwanhubId: vhub[i].id
  }
}]

// ------------------------------------------------------------------------------------------------
// VWAN VNET PEERINGS
// ------------------------------------------------------------------------------------------------
resource vhubNetConnections 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = [for i in range(0, length(vhub_net_connections)) : {
  parent: vhub[vhub_net_connections[i][0]]
  name: '${vhub_names[vhub_net_connections[i][0]]}-to-${vhub_net_connections[i][2]}'
  properties: {
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhub_names[vhub_net_connections[i][0]], 'defaultRouteTable')
      }
      propagatedRouteTables: {
        labels: [
          'default'
        ]
        ids: [
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vhub_names[vhub_net_connections[i][0]], 'defaultRouteTable')
          }
        ]
      }
    }
    remoteVirtualNetwork: {
      id: vhub_net_connections[i][1]
    }
    enableInternetSecurity: true
  }
}]

output id string = vwan.outputs.vwanId
