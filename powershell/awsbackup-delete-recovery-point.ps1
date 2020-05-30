#
# Delete AWS backup recovery point from specific Vault, filter by less than number of days
# using mixed power shell and aws cli
# 
#Usage
#.\aws-backup-delete-recovery-point-backup-vault-name.ps1 backupVault retentionDays
#

param (
    #AWS Region
    [string][Parameter(Position=0)]
    $region = "eu-west-2",
    #Backup Vault Name
    [string][Parameter(Position=1)]
    $backupVault = "BackupVaultName",
    #How much back in the past to go
    [int][Parameter(Position=2)]
    $retentionDays = -365
)

$date = Get-Date ((Get-Date).AddDays($retentionDays)) -Format "yyyy-MM-dd"
$recoveryPointARN = `
    (`
    aws backup list-recovery-points-by-backup-vault `
        --backup-vault-name $backupVault `
        --region $region `
        --query "RecoveryPoints[].RecoveryPointArn" `
        --by-created-before (Get-Date).AddDays($retentionDays) `
        --output text `
    ).Split()

$beforeDate = $recoveryPointARN.Length

echo "Total Backups= $beforeDate, before $date"

#looping through the 'RecoveryPointArn' and delete one by one
foreach($recoveryPoint in $recoveryPointARN) {
    aws backup delete-recovery-point --backup-vault-name $backupVault --recovery-point-arn $recoveryPoint
    echo "$beforeDate. $recoveryPoint Deleted"
    $beforeDate--
}


echo "Total Backups left= $beforeDate, before $date"
