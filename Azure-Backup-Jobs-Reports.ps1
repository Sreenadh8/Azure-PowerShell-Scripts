<#
#          Script: Azure VM Backup Reports                                           
#          Date: 02-06-2022                                                                     
#          Author: SreenadhReddy@hotmail.com
#

Prerequisites:

1) Azure Powershell
2) Azure CLI
3) SMTP creds if you want have reports over email

DESCRIPTION:
This script will pull the Azure VM's, FileShares Backup Jobs status for all Subscriptions. Details will be stored under the folder "c:\AzureBackupReports"
# Please replace the SMTP/Email variables as per your requirements( SMTP endpoit, TO_address , FROM_address ---etc )
#>

Param()

# Recording Script Start Date & Time.

$Script_Start_Time = Get-date

# Disable the Suppress Azure PowerShell Breaking Change Warnings
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

Write-Host "VERBOSE: Script Execution Start Date & Time : $Script_Start_Time" -ForegroundColor Cyan

$DateTime = Get-Date -Format ddMMyyyy-HHmmss

# Final Output Path.

$Output_Folder_Path = "C:\AzureBackupReports\"
$Output_Path_CSV = $Output_Folder_Path + "AzureBackupJobListReport" +"-" + "$DateTime" + ".csv"
$Output_Path_XLSX = $Output_Folder_Path + "AzureBackupJobListReport" +"-" + "$DateTime" + ".xlsx"

Write-Host "VERBOSE: CSV Output File Path : $Output_Path_CSV" -ForegroundColor Cyan
Write-Host "VERBOSE: XLSX Output File Path : $Output_Path_XLSX" -ForegroundColor Cyan

# Connect to Azure using Azure CLI.

az login --identity

# Connect to Azure using Azure PowerShell.

Connect-AzAccount -Identity

# Getting List of Subscriptions.

$Subscription_List = Get-AzSubscription | Select-Object -ExpandProperty id
(Get-AzSubscription).Name

# 
foreach ($Subscription in $Subscription_List){
    
    $x++
    $Subscription_Name = Get-AzSubscription -SubscriptionId $Subscription | Select-Object -ExpandProperty Name
    
    #Write-Progress -activity $Subscription_Name -PercentComplete ($x/$Subscription_List.Count*100) -Status $Subscription_Name

    $Current_Subscription_CLI= az account set --subscription $Subscription
    $Current_Subscription_PS = Select-AzSubscription -Subscription $Subscription
    
    Write-Host "VERBOSE: Working on $Subscription_Name Subcription " -ForegroundColor Cyan

    # Getting Vault list from Recovery Services vault.

    $Vault_List = (Get-AzRecoveryServicesVault).Name

    (Get-AzRecoveryServicesVault).Name
    
    Foreach ($Vault in $Vault_List){
        
        # Getting Vault Resource Group Name.

        $Vault_ResourecGroup = (Get-AzRecoveryServicesVault -Name $Vault).ResourceGroupName
        
        Write-Host "VERBOSE: Working on Vault: $Vault" -ForegroundColor Cyan
        Write-Host "VERBOSE: Vault ResourceGroup Name: $Vault_ResourecGroup" -ForegroundColor Cyan
        
        #Setting Vault Context.
    
        Get-AzRecoveryServicesVault -Name $Vault | Set-AzRecoveryServicesVaultContext

        #Write-Progress -activity $Subscription_Name -PercentComplete ($x/$Subscription_List.Count*100) -Status $Vault
                
        $obj = @()
        $results = @()
        
        $Backup_JOb_List = az backup job list -g "$Vault_ResourecGroup" -v "$Vault" | ConvertFrom-Json

        # Get only last day backup report. Use below commands and comment above $Backup_JOb_List.
        # $Time_Range = (Get-Date).AddDays(-1).ToString('dd-MM-yyyy')
        #$Backup_JOb_List = az backup job list -g "$Vault_ResourecGroup" -v "$Vault" --start-time "$Time_Range" | ConvertFrom-Json
        
        Foreach ($Backup_Job in $Backup_JOb_List){

            $Backup_Job_ID = $Backup_Job.name    
            $Backup_Job_Detail = az backup job show -n "$Backup_Job_ID" -g "$Vault_ResourecGroup" -v "$Vault" | ConvertFrom-Json
            $Backup_Job_Task = $Backup_Job_Detail.properties.extendedInfo.tasksList.taskId 

                $obj = New-Object -TypeName PSobject
                $obj | Add-Member -MemberType NoteProperty -Name Subscription -Value $Subscription_Name
                $obj | Add-Member -MemberType NoteProperty -Name ResouceGroup -Value $Vault_ResourecGroup
                $obj | Add-Member -MemberType NoteProperty -Name Vault -Value $Vault
                $obj | Add-Member -MemberType NoteProperty -Name JobID -Value $Backup_Job.name
                $obj | Add-Member -MemberType NoteProperty -Name ServerName -Value $Backup_Job.properties.entityFriendlyName
                $obj | Add-Member -MemberType NoteProperty -Name JobType -Value $(if($Backup_Job.properties.jobtype -eq "MabJob") { 'File and Folder' } else{ 'Snapshot'})
                $obj | Add-Member -MemberType NoteProperty -Name Status -Value $Backup_Job.properties.status
                $obj | Add-Member -MemberType NoteProperty -Name Task -Value $("$Backup_Job_Task")
                $obj | Add-Member -MemberType NoteProperty -Name BackupSize -Value $Backup_Job_Detail.properties.extendedInfo.propertyBag.'Backup Size'
                $obj | Add-Member -MemberType NoteProperty -Name StartTime -Value $Backup_Job.properties.starttime.Split(".")[0]
                $obj | Add-Member -MemberType NoteProperty -Name Duration -Value $Backup_Job.properties.duration.Split(".")[0]
                $obj | Add-Member -MemberType NoteProperty -Name ErrorDetails -Value $(if($Backup_Job.properties.errordetails.errorstring -ne $null){$Backup_Job.properties.errordetails.errorstring.Split(".")[1]}else{'No Error found'})
                $obj | Add-Member -MemberType NoteProperty -Name Recommendations -Value $(if($Backup_Job.properties.errordetails.recommendations -ne $null){$Backup_Job.properties.errordetails.Recommendations.Split(".")[0]}else{'No Recommendations'})
                
                $results +=$obj

        } $results | Export-csv "$Output_Path_CSV" -Append -NoTypeInformation -Verbose
    }
}

# Exporting report to Excel.

$Export_To_Excel = Import-csv -Path "$Output_Path_CSV" | Export-Excel "$Output_Path_XLSX" -IncludePivotTable -PivotRows Subscription -PivotColumns Status,Jobtype -PivotData Status -Verbose

# Sending Email.

Write-Host "VERBOSE: Sending Email To : $To_Email_ID" -ForegroundColor Cyan

# Replace FROM and TO email ID's as per your requirements.
$To_Email_ID = "azure-IT-team@abcxyz.com"

$From = "AzureBackupReport@abcxzy.com"
Write-Host "VERBOSE: Sending Email From : $From" -ForegroundColor Cyan

# Replace SMTP Server endpoint with your organization parameters...

$SMTP_Server = "smtp.abcxyz.com"

$Attachment = "$Output_Path_XLSX"
Write-Host "VERBOSE: Attachment Path : $Attachment" -ForegroundColor Cyan

$Subject = "Azure Backup Reports on $Script_Start_Time"
Write-Host "VERBOSE: Sending Email Subject Name : $Subject"

$txt1 = "Hello,

Please find attached Azure Backup Report executed on $Script_Start_Time.

Please check and take appropriate actions accordingly.

Thanks!

Automation Team.  
"
$Body = $txt1

Send-MailMessage -From $From -to $To_Email_ID -subject $Subject -Body $Body -SmtpServer $SMTP_Server -Port 25 -Attachments $Attachment -Verbose

$Script_End_Time = Get-date

Write-Host "VERBOSE: Script Execution End Date & Time : $Script_End_Time" -ForegroundColor Cyan
