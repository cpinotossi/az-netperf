# az-netperf

Simple netperf installation on Microsoft Azure for Performance Testing.

This template does setup an Azure Linux VM with ![netperf](https://github.com/HewlettPackard/netperf).

![Why netperf is the right choice.](https://cloud.google.com/blog/products/networking/using-netperf-and-ping-to-measure-network-latency)

## Deploy

## Get your current IP

Access to the VM is protected via an Network Security Group. To be able to access the VM and run netperf test you will need to add your client ip as parameter during the Azure deployment or you will need to modify the Network Security Group afterwards.

Retrieve your client IP with curl via an Akamai Service:

~~~~bash
curl whatismyip.akamai.com
84.128.90.114
~~~~

## Deploy the ARM Template

### Using Azure CLI

You will need to create a resource group first

~~~~bash
az group create --subscription <your-subscription-id> -n netperf-rg -l westeurope
~~~~

Afterwards you can deploy the ARM Template deploy.json:

~~~~bash
az deployment group create --subscription <your-subscription-id> --resource-group netperf-rg --mode Incremental --name netperf-deploy --template-file deploy.json --parameters clientip='84.128.90.114'
~~~~

### Using Azure Portal

In case you like to deploy via the portal just click the deploy button next:

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcpinotossi%2Faz-netperf%2Fmain%2Fdeploy.json)  

## Start RTT Test from your client

~~~~bash
netperf -H 52.157.216.29,4 -v 2 -Z 0+01tdTzPwjcIFM/sphtJQ== -P 1 -t TCP_RR -- -O min_latency,mean_latency,max_latency
~~~~

## Bastion

The ARM Template will also install a Bastion Host which will allow you to log into the VM via the Azure Portal.

NOTE: This way we avoid to have to keep Port 22 open on the vm.

## Clean up

if you like to clean up you can use the following CLI commend which will deploy an empty ARM Template with mode complete:

~~~~bash
az deployment group create --subscription <your-subscription-id> --resource-group netperf-rg --mode complete --name netperf-delete--deploy --template-file ignore/empty.json
~~~~

## Details

### Install Script

Installation of netperf happens via the Azure VM [CustomScript Extension](https://github.com/Azure/azure-linux-extensions/tree/master/CustomScript) for linux which will execute the following command on the Linux VM after installation:

~~~~bash
 #!/bin/sh
echo "Updating packages ..."
sudo apt-get -qq update
echo "Install netperf ..."
sudo apt-get -qq install netperf
echo "kill netperf ..."
sudo killall -9 netserver
echo "Start netperf in deamon mode ..."
sudo netserver -d -p 12865 -4 -v 2 -Z 0+01tdTzPwjcIFM/sphtJQ==
~~~~

Therefore we needed to encode the shell commands with base64 as follow:

~~~~bash
cat script.sh | base64 -w0
ICMhL2Jpbi9zaA0KZWNobyAiVXBkYXRpbmcgcGFja2FnZXMgLi4uIg0Kc3VkbyBhcHQtZ2V0IC1xcSB1cGRhdGUNCmVjaG8gIkluc3RhbGwgbmV0cGVyZiAuLi4iDQpzdWRvIGFwdC1nZXQgLXFxIGluc3RhbGwgbmV0cGVyZg0KZWNobyAia2lsbCBuZXRwZXJmIC4uLiINCnN1ZG8ga2lsbGFsbCAtOSBuZXRzZXJ2ZXINCmVjaG8gIlN0YXJ0IG5ldHBlcmYgaW4gZGVhbW9uIG1vZGUgLi4uIg0Kc3VkbyBuZXRzZXJ2ZXIgLWQgLXAgMTI4NjUgLTQgLXYgMiAtWiAwKzAxdGRUelB3amNJRk0vc3BodEpRPT0NCg==
~~~~

This content has been referenced inside the ARM Template "deploy" as part of the "Microsoft.Compute/virtualMachines/extensions" Resource.

## Helpfull Links

- ![ARM Template VM Reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/2019-03-01/virtualmachines/extensions#VirtualMachineExtensionProperties)
- ![VM Custom Script Extension example with Ubuntu](https://github.com/Azure/azure-quickstart-templates/tree/master/201-customscript-extension-public-storage-on-ubuntu)
- ![Azure VM Script Extension Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux)
- ![Netperf on Github](https://github.com/HewlettPackard/netperf) 
- ![Netperf Manual on Github](https://github.com/HewlettPackard/netperf/blob/master/doc/netperf.pdf)

## Netperf cheatsheet

### How to start the netserver?

~~~~bash
:~$ sudo netserver -d -p 12865 -4 -v 2 -Z 0+01tdTzPwjcIFM/sphtJQ== 
~~~~

For better debugging you can run in none Deamon mode as follow:

~~~~bash
:~$ sudo netserver -D -d -p 12865 -4 -v 2 -Z huhu 
~~~~

### How to verify if netserver is running?

~~~~bash
:~$ ps -aux | grep netserver
root     23158  0.0  0.0   9788   136 ?        Ss   21:47   0:00 /usr/bin/netserver
userone 24779  0.0  0.0  12944   932 pts/0    S+   22:05   0:00 grep --color=auto netserver
~~~~

## How to verify if port 12865 is used?

~~~~bash
:~$ ss -plnt sport eq :12865
State      Recv-Q Send-Q Local Address:Port               Peer Address:Port         
     
LISTEN     0      128           :::12865                     :::*              
~~~~

or

~~~~bash
:~$ sudo netstat -tnlp | grep :12865
tcp6       0      0 :::12865                :::*                    LISTEN      2315
8/netserver 
~~~~

## How to kill the netserver?

~~~~bash
:~$ sudo killall -9 netserver
~~~~