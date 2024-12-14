# Azure KQL Security Review: Demo Environment
_Review your Azure security with the power of KQL!_

> :snowflake: This lab was created as a part of [Cloud Security Podcast's "24 Days of Cloud"](https://advent.cloudsecuritypodcast.tv/) video event. Check it out!

Are you still waiting on CSPM budget? Have a few unmanaged Azure tenants to review? Or just curious to see your subscription's public Azure exposure?

The [Azure Resource Graph Explorer](https://portal.azure.com/#view/HubsExtension/ArgQueryBlade) can help! This web interface lets you query all your Azure infrastructure for common exposures. Try this lab out for a quick introduction on how KQL queries in the Resource Graph Explorer can help you report on VM, Storage, and Cosmos DB network exposures.

## Purpose
This repository is an easy lab to demonstrate how [Azure Resource Graph's](https://learn.microsoft.com/en-us/azure/governance/resource-graph/) KQL searches can be used to provide a quick, high-level security review. The `terraform` directory will deploy a few Azure resources (VMs, storage, Cosmos DB) with various network exposures. Alternatively, you can run the [queries below](#demo-kql-security-review-queries) against your own existing environment without any risk of modifying infrastructure or generating alerts.

The [Azure Resource Graph Explorer](https://portal.azure.com/#view/HubsExtension/ArgQueryBlade) provides a fantastic, super-quick web query to a database of all Azure resources within an Azure tenant. (Access to query resources is based on your Reader or equivalent roles across the tenant.) This ability to query all resources and most resource properties at scale is incredibly helpful to understand all your Azure assets at once, especially when exploring network exposures and security issues.

More defenders should know about the power of KQL for quick security reporting! It's my hope this lab can get you started.

### Walkthrough
You can find a walkthrough of this lab content as part of Cloud Security Podcast's "24 Days of Cloud" event on Day 14:
- [24 Days of Cloud: Day 14](https://advent.cloudsecuritypodcast.tv/)

Or, go straight to the walkthrough here:
- [Azure Security Assessments Using Resource Graph Explorer](https://www.youtube.com/watch?v=XqNsmfaBZ6Y)

### New to Terraform?
If Terraform is new to you, don't worry: The code is broken into several small files that work with the with the `azurerm` resource provider to create configurations in your own Azure test environment. The goal of presenting content in this way is to make it easy to quickly understand and adapt if you want to play with these files.

### Cost?
The cost of running this demo environment for a couple hours should be below $5 USD. If you're concerned about running up costs, use `terraform destroy` whenever you aren't actively playing with the lab. Running these queries against an existing Azure environment to see what turns up is free.

This also makes the Azure Resource Graph Explorer a great way to start environment review before your CSPM budget kicks in.

## Structure
Demo KQL queries for this lab and sample security reviews are available [further down this page](#demo-kql-security-review-queries).

All resources are created from the `terraform` directory. This code creates the following Azure resources:
- `01-locals.tf`: Configuration variables. Also creates the resource group `kql-demo-env-rg`.
- `02-vms.tf`: Creates 2 VMs, 1 Windows and 1 Linux, with different NSG exposures.
- `03-storage.tf`: Creates 3 storage accounts with different exposure and network rules.
- `04-cosmosdb.tf`: Creates 2 Cosmos DB instances, 1 public and 1 private. WARNING: Takes up 5 minutes to create, and up to 20 minutes to delete! Remove this file from the folder if you're in a hurry.
- `05-outputs.tf`: Output shown to the user when the Terraform run completes.

It's not very complex, just split across multiple files for readability.

## Usage
1. Ensure you are logged in as a user with Owner or equivalent rights to create resources in an Azure subscription by executing `az login` from a terminal session.
2. If you need resources created in a specific subscription, set your session to that subscription using `az account set --subscription [id]`.
3. _(Optional)_ Remove the `4-cosmosdb.tf` file if you don't want to wait 20 minutes to clean up this environment.
4. From the `terraform` folder, execute `terraform init` + `terraform apply`. Type "yes" to apply. Deployment will take around 5 minutes, so grab a cup of tea!
5. Open the Azure Resource Graph Explorer (https://portal.azure.com/#view/HubsExtension/ArgQueryBlade), or check your Terraform output for a URL that will take you directly to the created resource group.
6. Play with KQL!! Sample queries to review these resources [are available below](#demo-kql-security-review-queries).
7. When you are done, execute `terraform destroy`. Cleanup will take around 20 minutes, if you included Cosmos DB.


## Demo KQL Security Review Queries

Queries are incremental. In other words, we'll start basic and work up towards a larger query that could be helpful for security review.
**NOTE:** If you're querying a large environment, you may get [rate limited by the Azure Resource Graph](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/request-limits-and-throttling#subscription-and-tenant-limits). 

### Virtual Machine Exploration

Let's start by exploring the VMs that were deployed. We'll end with a report of exposed VMs, by analyzing their attached NSGs.

This report will build on a [sample query from Microsoft](https://learn.microsoft.com/en-us/azure/governance/resource-graph/samples/advanced?tabs=azure-cli#list-virtual-machines-w[…]-interface-and-public-ip). While the last few queries look complex, don't let them intimidate you! They're just a copy-paste away.

If you're new to the concept of a `join`, try breaking the final three queries down (running each bit that starts with `resources`) to understand them better.

| # |  Task | Query|
|---|----|----|
| 1 | List all resources | resources |
| 2 | Compute resources | <pre>resources <br>\| where type contains "Microsoft.Compute" </pre> |
| 3 | Virtual machines | <pre>resources <br>\| where type =~ "Microsoft.Compute/virtualmachines"</pre> |
| 4 | Public IPs | <pre>resources <br>\| where type =~ "microsoft.network/publicipaddresses" <br>\| project properties.ipAddress</pre> |
| 5 | List of all public IPs | <pre>resources <br>\| where type =~ "microsoft.network/publicipaddresses"</pre> |
| 6 | Map all public IPs to their matching VMs | [Microsoft: Resource Graph - Advanced Queries](https://learn.microsoft.com/en-us/azure/governance/resource-graph/samples/advanced?tabs=azure-cli#list-virtual-machines-w[…]-interface-and-public-ip) |
| 7 | Network Security Group Rules (ACLs) exposed to the public internet | <pre>resources<br>\| where type == "microsoft.network/networksecuritygroups"<br>\| extend securityRules = properties.securityRules<br>\| mv-expand rule = securityRules<br>\| where tostring(rule.properties.access) == "Allow"<br>   and tostring(rule.properties.direction) == "Inbound"<br>   and tostring(rule.properties.destinationAddressPrefix) == "*"<br>\| project id, name, subscriptionId, resourceGroup, ruleName = tostring(rule.name), access = tostring(rule.properties.access), port = tostring(rule.properties.destinationAddressPrefix), direction = tostring(rule.properties.direction)</pre> |
| 8 | **Report** List VMs with public exposure, based on NSG ACLs | <pre>resources<br>\| where type == "microsoft.network/networksecuritygroups"<br>\| extend securityRules = properties.securityRules<br>\| mv-expand rule = securityRules<br>\| where tostring(rule.properties.access) == "Allow"<br>   and tostring(rule.properties.direction) == "Inbound"<br>   and tostring(rule.properties.destinationAddressPrefix) == "*"<br>\| project nsgId = id, nsgName = name, ruleName = tostring(rule.name), access = tostring(rule.properties.access), port = tostring(rule.properties.destinationPortRange), direction = tostring(rule.properties.direction), subscriptionId, resourceGroup<br>\| join kind=inner (<br>    resources<br>    \| where type == "microsoft.network/networkinterfaces"<br>    \| mv-expand nsg = properties.networkSecurityGroup<br>    \| project nicId = id, nicName = name, vmId = tostring(properties.virtualMachine.id), nsgId = tostring(nsg.id)<br>) on nsgId<br>\| join kind=inner (<br>    resources<br>    \| where type == "microsoft.compute/virtualmachines"<br>    \| project vmId = id, vmName = name, vmLocation = location<br>) on vmId<br>\| project subscriptionId, resourceGroup, vmName, nicName, nsgName, ruleName, access, port, direction, nsgId</pre> |

### Storage Exploration 

We'll continue by building a query to uncover exposed storage accounts.

Enabling public network access doesn't always mean a storage account is exposed to the world! We'll refine our initial search by specifying storage with a default network action of "Allow" to improve our final report.

This will filter out a storage account that allows just our IP to connect, since this isn't the kind of account we're looking for.

| # |  Task | Query|
|---|----|----|
| 1 | Storage accounts | <pre>resources<br>\| where type contains 'microsoft.storage'</pre> |
| 2 | Storage accounts within just our demo resource group | <pre>resources<br>\| where type contains 'microsoft.storage'<br>\| where resourceGroup == "kql-demo-env-rg"</pre> |
| 3 | Storage accounts allowing public network access | <pre>resources<br>\| where type contains 'microsoft.storage' <br>\| where resourceGroup == "kql-demo-env-rg" <br>\| where properties.publicNetworkAccess == "Enabled"</pre> |
| 4 | Storage accounts exposed to _all_ public networks | <pre>resources<br>\| where type contains 'microsoft.storage' <br>\| where resourceGroup == "kql-demo-env-rg" <br>\| where properties.publicNetworkAccess == "Enabled" <br>\| where properties.networkAcls.defaultAction == "Allow"</pre> |
| 5 | **Report** List storage exposed to all public networks | <pre>resources<br>\| where type contains 'microsoft.storage' <br>\| where resourceGroup == "kql-demo-env-rg" <br>\| where properties.publicNetworkAccess == "Enabled"<br>\| project subscriptionId, resourceGroup, name, properties.networkAcls.ipRules, id</pre> |

### Cosmos DB Exploration

Let's finish by looking at Cosmos DB. While network exposure is worth considering, this is also a great example of pulling a resource inventory.

In 2021, Wiz released a report on the "Chaos DB" vulnerability. [In their remediation guidance](https://www.wiz.io/blog/protecting-your-environment-from-chaosdb#remediation-short-term-immediate-steps-27), they suggested rotating Cosmos DB keys for all databases as a method to ensure data could not be accessed by attackers.

For this scenario, we'll work up to creating a resource inventory of Cosmos DB instances and when their keys were last changed. This will make it clear which databases still need their keys updated.

| # |  Task | Query|
|---|----|----|
| 1 | Cosmos DB instances | <pre>resources<br>\| where type =~ 'microsoft.documentdb/databaseaccounts'</pre> |
| 2 | Cosmos DB instances with public network access enabled | <pre>resources<br>\| where type =~ 'microsoft.documentdb/databaseaccounts'<br>\| where properties.publicNetworkAccess == "Enabled"</pre> |
| 3 | Cosmos DB instances, listed with their associated key metadata | <pre>resources<br>\| where type =~ 'microsoft.documentdb/databaseaccounts'<br>\| project name, subscriptionId, resourceGroup, properties.publicNetworkAccess, properties.keysMetadata</pre> |
| 4 | **Report** List Cosmos DB resources with last key rotation times | <pre>resources<br>\| where type =~ 'microsoft.documentdb/databaseaccounts'<br>\| project name, subscriptionId, resourceGroup, public = properties.publicNetworkAccess, primaryLastRotated = properties.keysMetadata.primaryMasterKey.generationTime, secondaryLastRotated = properties.keysMetadata.secondaryMasterKey.generationTime, primaryReadOnlyLastRotated = properties.keysMetadata.primaryReadonlyMasterKey.generationTime, secondaryReadonlyLastRotated = properties.keysMetadata.secondaryReadonlyMasterKey.generationTime</pre> |

## Further Resources
- Azure Resource Graph Explorer: https://portal.azure.com/#view/HubsExtension/ArgQueryBlade
- Understanding the Azure Resource Graph query language: https://learn.microsoft.com/en-us/azure/governance/resource-graph/concepts/query-language
- Starter Resource Graph query samples: https://learn.microsoft.com/en-us/azure/governance/resource-graph/samples/starter?tabs=azure-cli
- Advanced Resource Graph query samples: https://learn.microsoft.com/en-us/azure/governance/resource-graph/samples/advanced?tabs=azure-cli