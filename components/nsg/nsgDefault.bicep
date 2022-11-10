param tags object

resource nsgDefault 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg-default'
  location: resourceGroup().location
  properties: {}
  tags: tags
}

output id string = nsgDefault.id
