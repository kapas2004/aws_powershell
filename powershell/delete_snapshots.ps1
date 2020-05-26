#
#.\snapshotDelete.ps1 "region" "older than days" "confirm delete" "tagKey" tagValue" "*"_or_"InstanceId"
#
[CmdLetBinding()]
param (
    [string][Parameter(Position=0)]
    $region = "eu-west-2",
    [string][Parameter(Position=1)]
    $ownerID = "xxxxxxxxxxxx",
    [int][Parameter(Position=2)]
    $startTime = -1,
    [boolean][Parameter(Position=3)]
    $delete = $true,
    [string][Parameter(Position=4)]
    $tagkey = "Description",
    [string][Parameter(Position=5)]
    $tagvalue = "ALL Server",
    [string][Parameter(Position=6)]
    $instancemanual = "*"
)


$getDate = (Get-Date (Get-Date).AddDays($startTime) -Format "yyyy-MM-dd")
if ($instancemanual -eq "*"){
	#Collect Volumes
	$instances = aws ec2 describe-instances --region eu-west-2 --query "Reservations[*].Instances[*].[InstanceId]" --output text
	#$instances = aws ec2 describe-instances --region $region --filters "Name=instance-id, Values=$instancemanual" --query "Reservations[*].Instances[*].[InstanceId]" --output text
	$fileName = "Deleted-$tagvalue"+"s AllSnapshots"
}
else {
	#single instance
	$instances = aws ec2 describe-instances --region $region --filters "Name=instance-id, Values=$instancemanual" --query "Reservations[*].Instances[*].[InstanceId]" --output text
	$fileName = "Deleted-$tagvalue"+"s Snapshots "+$instancemanual
}


try {
    New-Item -Path .\$fileName.csv -ItemType File -Force
    Add-Content -Path .\$fileName.csv -Value "Deleting Snapshots older than $getdate"
    Add-Content -Path .\$fileName.csv -Value "Region:,$region"
    Add-Content -Path .\$fileName.csv -Value "Description tag:,$tagValue"
    Add-Content -Path .\$fileName.csv -Value ""
    Add-Content -Path .\$fileName.csv -Value "Server Name, InstanceID Snaphost Name,Volume, Date Created,Snapshot, Deleted"
}
catch
{
    exit 1
}

$snapCount = ((aws ec2 describe-snapshots --owner-id $ownerID --region 'eu-west-2' --output json | ConvertFrom-Json).Snapshots.SnapshotId).Count
echo "Number of snapshots in $region to be messed with up: $snapCount"

foreach($instance in $instances) {
    $instanceName = aws ec2 describe-instances --output text --filters "Name=instance-id, Values=$instance" --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value | [0]]'
    $volumes = (aws ec2 describe-instances --instance-ids $instance --query Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId --output text).Split("	")
    foreach($volume in $volumes) {
        $count = 0
        $snapshots_to_delete = ""

        #$getDate = (Get-Date (Get-Date).AddDays($startTime) -Format "yyyy-MM-dd")

        #check id snapshots exests for delete
        $snapexists=(aws ec2 describe-snapshots --owner-id $ownerID --filters "Name=volume-id, Values=$volume" --query "Snapshots[].SnapshotId" --output text)

        if($snapexists -ne $null){
            $snapshots_to_delete=(aws ec2 describe-snapshots --owner-id $ownerID --filters "Name=volume-id, Values=$volume" --query "Snapshots[].SnapshotId" --output text).Split("	")
            
    
            #failsafe
            if($delete -eq $true){
                #list what is going to be deleted
                echo ""
                echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
                echo "Deleteing snapshots older than $getDate on $instanceName"
                echo "********************************************************"
                echo $snapshots_to_delete
                echo "-------------------------------------------------"
                    
                # actual deletion
                echo ""
                echo "-------------------------------------------------"
                echo "Snapshots deletion started"
                echo "**************************"
                
                
                foreach($snap in $snapshots_to_delete){
                    try{
                        #get the snapshots start time
                        $dateCreated = Get-date (aws ec2 describe-snapshots --owner-id $ownerID --filters --snapshot-ids $snap --query Snapshots[*].StartTime --output text) -Format "yyyy-MM-dd"
                        
                        if($getDate -lt $dateCreated) {
                            aws ec2 delete-snapshot --snapshot-id $snap 2>err.txt

                            if((Get-Content -Path .\err.txt | Where-Object {$_ -match 'InvalidSnapshot.InUse'}).Length -ne 0){
                                Write-Host (Get-Content -Path .\err.txt | Where-Object {$_ -match 'InvalidSnapshot.InUse'})
                                Add-Content -Path .\$fileName.csv -Value "$instanceName,$instance,$volume,$dateCreated,$snap, InUse"
                            } 
                        
                            elseif ((Get-Content -Path .\err.txt | Where-Object {$_ -match 'InvalidSnapshot.NotFound'}).Length -ne 0)
                            {
                                Write-Host  (Get-Content -Path .\err.txt | Where-Object {$_ -match 'InvalidSnapshot.NotFound'})
                                Add-Content -Path .\$fileName.csv -Value "$instanceName,$instance,$volume,$dateCreated,$snap, Not Found"
                            }
                            else{
                                echo "Snapshot for $instanceName, id: $instance, vol: $volume, created on: $dateCreated is deleted: $snap"
                                Add-Content -Path .\$fileName.csv -Value "$instanceName,$instance,$volume,$dateCreated,$snap, $True"
                                $count++
                                }
                        }
                    }
                    catch{
                        echo "Error"
                    }
                }    
                
                echo "-------------------------------------------------"
                echo ""
                echo "Total snapshots deleted : $count"
                echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
                echo ""                
            }
            else{
            echo ""
            echo "$instanceName, id: $instance, No Snapshot to be deleted."
            Add-Content -Path .\$fileName.csv -Value "$instanceName,$instance,$volume,$dateCreated,$snap, $False"
        }
        }
        else{
            echo ""
            echo " $instanceName, id: $instance, No Snapshot to be deleted."
            Add-Content -Path .\$fileName.csv -Value "$instanceName,$instance,$volume,$dateCreated,$snap, $False"
        }
    }
}
Remove-Item -Path .\err.txt
echo "err.txt file removed."
echo "Done."

