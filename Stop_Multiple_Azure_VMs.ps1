

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


