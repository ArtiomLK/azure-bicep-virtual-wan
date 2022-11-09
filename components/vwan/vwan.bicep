param vwan_n string
param location string

param tags object = {}

resource vwanDeployed 'Microsoft.Network/virtualWans@2021-03-01' = {
  name: vwan_n
  location: location
  properties: {
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    disableVpnEncryption: false
    type: 'standard'
  }
  tags: tags
}

output vwanId string = vwanDeployed.id
