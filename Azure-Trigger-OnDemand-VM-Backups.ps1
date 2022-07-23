###############################################################
# 
#  Author : Sreenadhreddy@hotmail.com    
#  Description : This PowerShell script will help you to trigger on-demand backups for given VM's in an RSV...
#                
#  
###############################################################

#Provide the Subscription name

$subName = "My-Test-Subscription"

#Selecting Azure subscription
Select-AzSubscription -Subscription $subName

#Provide the resourcegroup Name of Azure Recovery Service Vault...

$Vault-RG = "My-RG01"

#Provide the RSV Vault Name..

$vaultName = "My-RSV01"

#Provide VM's List which are registered with above given RSV.

$vmlist="My-VM01";"My-VM02"

#Change the retention period days as per your requirement...

$RetentionDays = 7
$currentDate = Get-Date
$RetailTill = $currentDate.AddDays($RetentionDays)
Write-Output ("Recoverypoints will be retained till " + $RetailTill)

#Collect Vault Details
$vault = Get-AzRecoveryServicesVault -ResourceGroupName $Vault-RG -Name $vaultName
$vault | Set-AzRecoveryServicesVaultContext
foreach($vm in $vmlist)
{ 
    write " backup for - $vm"
    #Collect Container Details of the Backup Protected VM
    $Container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -Status Registered -VaultId $vault.ID -FriendlyName $vm
    $Container

    $BackupItem = Get-AzRecoveryServicesBackupItem  -Container $Container -WorkloadType AzureVM -VaultId $vault.ID
    write "************************************" 
    $BackupItem        
    #Trigger OnDemand backup
    $backupstatus =  Backup-AzRecoveryServicesBackupItem -Item $BackupItem -ExpiryDateTimeUTC $RetailTill

    write " backup triggered for $vm  ************************************"   
}
