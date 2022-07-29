###############################################################
# 
#  Author : sreenadhreddy@hotmail.com    
#  Description : This PowerShell script will help you to delete multiple snapshots which are older X days...
#                
#  
###############################################################

# Provide the Subscription name, VM names, Snapshots Tag, 'Older than X days' variable inputs...

Param
(
  
  [Parameter (Mandatory= $true)]
  [string]$SubName,
  [Parameter (Mandatory= $false)]
  [string]$Enter_Snapshot_Tag_Key,
  [Parameter (Mandatory= $false)]
  [string]$OlderThanXdays = "14"


)



# Provide VM Names & Resource Group details, these can be changed as per your requirement...

try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity -Subscription "$SubName" | Out-Null
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

#Get-AzSnapshot

$Enter_Snapshot_Tag_Key

$snaps = Get-AzSnapshot | where{$_.tags.Keys -eq "$Enter_Snapshot_Tag_Key"} | where{($_.TimeCreated) -lt ([datetime]::Today.AddDays(-"$OlderThanXdays"))} |Remove-AzSnapshot -Force

#$Snaps

