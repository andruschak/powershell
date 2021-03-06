# Variables for common values
# from - https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/virtual-machines-linux-powershell-sample-create-vm?toc=%2fpowershell%2fmodule%2ftoc.json
#
# before running execute: "Login-AzureRmAccount" and enter your azure user/pass
#
# this will lump the vm-nic, vm-nsg, etc to the resource group - if you want to delete, turf the resource group (see below)


$resourceGroup = "az-lab-rg"
$location = "westus"
$vmName = "az-lab-server1"

# Definer user name and blank password
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)




# Create a resource group
New-AzureRmResourceGroup -Name $resourceGroup -Location $location




# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name az-lab-Subnet -AddressPrefix 10.12.1.0/24

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name az-lab-vNET -AddressPrefix 10.12.0.0/16 -Subnet $subnetConfig

# Create a public IP address and specify a DNS name, was "mypublicdns$(Get-Random)" for random name
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "az-lab-publicdns" -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name az-lab-NetworkSecurityGroupRuleSSH  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 22 -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name az-lab-NetworkSecurityGroup -SecurityRules $nsgRuleSSH

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface -Name az-lab-Nic -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id




# Actual vm piece
# Was -VMSize Standard_D1, but we want to use the free tier

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_D1 | `
Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred -DisablePasswordAuthentication | `
Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic.Id


# Need to configure youre ssh keys
# after choco install putty you can use puttygen to generate keys or git bash with ssh-keygen.exe (recommended way!!)
# open git-bash command (after git install from choco), cd ~, ssh-keygen, only hit enter and it will save them to the proper locations

# Configure SSH Keys
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
Add-AzureRmVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path "/home/tandr/.ssh/authorized_keys"

# Create a virtual machine
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig


# The removal command, reference at the beginning - delete the resource group
# Remove-AzureRmResourceGroup -Name az-lab-rg