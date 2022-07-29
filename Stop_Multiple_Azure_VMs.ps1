###############################################################
# 
#  Author : Sreenadhreddy@hotmail.com    
#  Description : This PowerShell script will help you to stop multiple VM's...
#  
#  Pre-requisites:
#  1) AZ PowerShell Module ( install-module -Name Az -Force )
# 
#  
###############################################################

#Provide the Subscription name, VMnames and RG as variable inputs
# Enter the VMnames variable in this array format :  ['vm1','vm2','vm3']

Param
(
  
  [Parameter (Mandatory= $true)]
  [string]$Enter_Subscription_Name,
  [Parameter (Mandatory= $true)]
  [string[]]$VMNames,
  [Parameter (Mandatory= $true)]
  [string]$Enter_ResourceGroup_Name
)

try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity -Subscription "$Enter_Subscription_Name" -Force
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

foreach ( $vm in $VMNames )

{

Stop-AzVm -Name $vm -ResourceGroupName $Enter_ResourceGroup_Name -Force


}


