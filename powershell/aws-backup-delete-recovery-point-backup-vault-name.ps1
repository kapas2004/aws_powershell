#
# Delete AWS backup recovery point from specific Vault, filter by less than number of days
# Usage
#.\aws-backup-delete-recovery-point-backup-vault-name.ps1 backupVault retentionDays
#

$backupVault = "PPDServer"
$retentionDays = 0
$date = Get-Date ((Get-Date).AddDays($retentionDays)) -Format "yyyy-MM-dd"
$recoveryPointARN = `
    (`
    aws backup list-recovery-points-by-backup-vault `
        --backup-vault-name $backupVault `
        --region "eu-west-2" `
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
