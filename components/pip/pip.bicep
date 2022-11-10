
param tags object
param pip_n string

resource bastionPublicIpAddress 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: pip_n
  tags: tags
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

output id string = bastionPublicIpAddress.id
