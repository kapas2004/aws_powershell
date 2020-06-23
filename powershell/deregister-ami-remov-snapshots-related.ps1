#
# Created by kapas2004
#
# Deregister AMIs and remove the snapshots related to it
# Region based
# using mixed powershell and aws cli
# 
#Usage
#.\deregister-ami-remov-snapshots-related.ps1
#
# 

$ownerID = 'xxxxxxxxxxxx'
$region = 'eu-west-1'

$ec2Ins = (aws ec2 describe-instances --region $region --query "Reservations[].Instances[].InstanceId" --output text).Split()
 
foreach($deregisterAMIbyEC2ID in $ec2Ins){
    #Deregister AMI by Instance ID in Description
    #Ex: Created by CreateImage(i-0cd8054e6a65d7324) for ami-0ec516e065151c353 from vol-0d927de1e75bd47d5
    $descriptions = (aws ec2 describe-snapshots --owner-ids $ownerID --region $region --filters Name=description,Values="*$deregisterAMIbyEC2ID*"  --query "Snapshots[].Description" --output text).Split('	')
    $countAMIs = 0
    $startAmi = ''
    foreach($description in $descriptions){
        $descriptionSplit = $description.Split(' ')
        $amiID = $descriptionSplit[4]
        $instanceId = $descriptionSplit[2].Split('\(([^)]+)\)')[1]
        $temp = ''
        if($startAmi -ne $amiID){
            if($instanceId -eq $deregisterAMIbyEC2ID){                
                $temp = (aws ec2 deregister-image --region $region --image-id $amiID) 2>&1
                if(($temp -like '*AuthFailure*') -or ($temp -like '*InvalidParameterValue*') -or ($temp -eq '')  -or ($temp -like '*InvalidAMIID.Unavailable*')){
                    Write-Output "$(($countAMIs+1)). Skipped deregistering $amiID"
                    $countAMIs += 1                    
                }
                else{
                    $startAmi = $amiID
                    Write-Output "$(($countAMIs+1)). Deregistering $amiID"
                    $countAMIs += 1                    
                }
            }
        }
    }
    Write-Output "Total AMI deregistered for $deregisterAMIbyEC2ID = $countAMIs"

    #delete snapshot
    $countSnapshots = 0
    $snapshots = (aws ec2 describe-snapshots --owner-ids $ownerID --region $region --filters Name=description,Values="*$deregisterAMIbyEC2ID*" --query "Snapshots[].[SnapshotId]" --output text).Split('	')
    foreach ($snapshot in $snapshots) {       
        $temp = (aws ec2 delete-snapshot --region $region --snapshot-id $snapshot) 2>&1
        if(($temp -like '*AuthFailure*') -or ($temp -like '*InvalidParameterValue*') -or ($temp -eq '')  -or ($temp -like '*InvalidAMIID.Unavailable*')){
            Write-Output "$(($countSnapshots+1)). Skipped removing $snapshot"
            $countSnapshots += 1
        }
        else{            
            Write-Output "$(($countSnapshots+1)). $snapshot Removed" 
            $countSnapshots += 1           
        }
    }
    Write-Output "Total snapshots removed for $deregisterAMIbyEC2ID = $countSnapshots"
}