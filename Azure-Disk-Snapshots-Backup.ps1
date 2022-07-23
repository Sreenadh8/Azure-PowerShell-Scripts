###############################################################
# 
#  Author : SreenadhReddy@hotmail.com    
#  Description : This PowerShell script will help you to create snapshots for given virtual machines respective disks[including OS + Data ]...
#                
#  
###############################################################

# Provide the Subscription name as variable input...

$subName = "My-Test-Subscription"

# Selecting Azure subscription

Select-AzSubscription -Subscription $subName

# Provide VM Names & Resource Group details, these can be changed as per your requirement...

$vmnames = "MY-VM01","MY-VM02","MY-VM03"
$rg = "MY-RG01"

foreach ($vm in $vmnames) { 

$vmproperties = Get-AzVM -Name $vm -ResourceGroupName $rg
$snapshotdisk = $vmproperties.StorageProfile

Write-Output "Creating Snapshot for OS disk $vm ..."

$osdisk = Get-Azdisk -ResourceGroupName $vmproperties.ResourceGroupName -DiskName $vmproperties.StorageProfile.OsDisk.Name
$OsSnapshotName = "$($vmproperties.Name)-OS-disk-created-$((Get-Date -f MM-dd-yyyy_HH_mm_ss))"

If ($OsSnapshotName.Length -ge 78)

{
    $OsSnapshotName = $OsSnapshotName.Substring(0, 78)
}

$OSsnapshot =  New-AzSnapshotconfig -SourceUri $OSdisk.Id -CreateOption Copy -Location $vmproperties.location

New-AzSnapshot -Snapshot $OSsnapshot -SnapshotName $OsSnapshotName -ResourceGroupName $vmproperties.ResourceGroupName -Verbose | Out-Null

$tag = @{VM_Name = "$vmproperties.name";created_date="$((Get-Date -f MM-dd-yyyy_HH_mm_ss))";backup_type="disk-snapshot"}

$NewOSsnapshot = Get-AzSnapshot -Name $OsSnapshotName -ResourceGroupName $vmproperties.ResourceGroupName

Set-AzResource -ResourceId $NewOSsnapshot.Id -Tag $tag -Force

## Data Disks

Write-Output "VM $($vmproperties.name) Data Disk Snapshots Begin"
 
    $dataDisks = ($snapshotdisk.DataDisks).name
 
        foreach ($datadisk in $datadisks) {
 
            $dataDisk = Get-AzDisk -ResourceGroupName $vmproperties.ResourceGroupName -DiskName $datadisk
 
            Write-Output "VM $($vmproperties.name) data Disk $($datadisk.Name) Snapshot Begin"
 
            $DataDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $dataDisk.Id -CreateOption Copy -Location $vmproperties.Location
            
            $snapshotNameData = "$($datadisk.name)_snapshot_$((Get-Date -f MM-dd-yyyy_HH_mm_ss))"

            
           If ($snapshotNameData.Length -ge 78)
            
            {
           $snapshotNameData = $snapshotNameData.Substring(0, 78)
            }


            New-AzSnapshot -ResourceGroupName $vmproperties.ResourceGroupName -SnapshotName $snapshotNameData -Snapshot $DataDiskSnapshotConfig | Out-Null
         
$tag = @{VM_Name = "$vmproperties.name";created_date="$((Get-Date -f MM-dd-yyyy_HH_mm_ss))";backup_type="disk-snapshot"}

$NewDataDiskSnapshot = Get-AzSnapshot -Name $snapshotNameData -ResourceGroupName $vmproperties.ResourceGroupName

Set-AzResource -ResourceId $NewDataDiskSnapshot.Id -Tag $tag -Force

Write-Output "VM $($vmproperties.name) data Disk $($datadisk.Name) Snapshot and Tagging tasks are completed" 

}
 
}
