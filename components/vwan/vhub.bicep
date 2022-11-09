param vwan_hub_n string
param location string
param vwan_hub_addr_prefix string
param vwanId string

param tags object = {}

resource vwanHubDeployed 'Microsoft.Network/virtualHubs@2021-02-01' = {
  name: vwan_hub_n
  location: location
  properties: {
    virtualWan: {
      id: vwanId
    }
    addressPrefix: vwan_hub_addr_prefix
  }
  tags: tags
}

output vwanhubId string = vwanHubDeployed.id
