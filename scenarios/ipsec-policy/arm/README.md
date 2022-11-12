# Connecting Vnets using VpnGw with Narrow Traffic Selectors for Segmentation

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fkayodenet%2Fazure-networking%2Fmaster%2Fpoc%2Fipsec-policy%2Farm%2Fazuredeploy.json)



This template deploys a specified number of VNETs (1 - 254), each with a small Windows VM. 

The address space in each VNET is unique: 10.0.<1-254>.0.

Purpose is to provide a test environment for the private preview of Azure Network Manager.

:exclamation: Your subscription must be whitelisted for the ANM private preview.

Usage:
- Create a resource group in West Central US.
- Deploy the template to the resource group.
- Deploy ANM to the resource group.
- Configure and test ANM per instructions provided in the whitelist message.
