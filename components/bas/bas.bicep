param bas_n string
param snet_bas_id string
param pip_id string
param location string = resourceGroup().location

resource bastionHost 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: bas_n
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: snet_bas_id
          }
          publicIPAddress: {
            id: pip_id
          }
        }
      }
    ]
  }
}
