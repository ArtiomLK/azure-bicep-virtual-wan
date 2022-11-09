param vpng_n string
param vpng_location string
param vwanhubId string

resource vwangwDeployed 'Microsoft.Network/vpnGateways@2020-05-01' = {
  name: vpng_n
  location: vpng_location
  properties: {
    vpnGatewayScaleUnit: 1
    virtualHub: {
      id: vwanhubId
    }
    bgpSettings: {
      asn: 65515
    }
  }
}

output vwangwId string = vwangwDeployed.id
