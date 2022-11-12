# Vnet Connectivity using VPN Gateway with Narrow Traffic Selectors for Segmentation

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fkayodenet%2Fazure%2Fmaster%2Fscenarios%2F01-vnet-vpn%2Fazuredeploy.json)

This template deploys a hub and spoke topology to test the connectivity of VNETs using VPN gateway custom traffic selectors.

## Design Requirements
1. A Hub and spoke topology connecting multiple Vnets.
2. The hub is a multi-tenant environment that hosts applications for various business units (BU).
3. Establish connectivity from VNET of each BU to the hub Vnet.
4. Each BU Vnet should only have routes to their dedicated subnet in the Hub Vnet.
5. Allow bi-directional sending of traffic between Hub Vnet and BU Vnet.
6. Allow on-premises locations of each BU access to only that BU's environemnt - i.e the BU Vnet and the dedicated BU subnet in the Hub Vnet.
