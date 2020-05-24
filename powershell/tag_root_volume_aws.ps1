#invoke command .\tag_root_volume_aws.ps1 "aws region"
#Add Tag Name to all Windows platform root volumes same as the Instance Name Tag plus (C) accross region
[CmdLetBinding()]
param (
    #Set region to be searched
    [string][Parameter(Position=0)]
    $region = "eu-west-2"
)
#Get all instances in the region set
$instances = (aws ec2 describe-instances --filter Name=platform,Values=windows --region $region --query "Reservations[].Instances[].InstanceId" --output text).split()
#count how many instances are
$count = 1
#write in sda1Tags.txt file
$temp1 ="Total Number of Instances contain /dev/sda1 volume: " + $instances.Count
$temp1  > sda1Tags.txt
echo $temp1
foreach($instance in $instances) {    
    #get the tagged Instance Name
    $TagValue = aws ec2 describe-instances --instance-ids $instance --filters Name=block-device-mapping.device-name,Values=/dev/sda1 --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value]" --output text
    #get the volumeId from volume description
    $sda1VolId = aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instance Name=attachment.device,Values=/dev/sda1 --query "Volumes[].Attachments[].VolumeId" --output text    
    #get the current tag if exists
    $currentTag = aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instance Name=attachment.device,Values=/dev/sda1 --query "Volumes[].Tags[?Key=='Name'].Value" --output text
    #add (C) to Instance Tag:Name at the end
    $TagValueC = $TagValue + " (C)"
    #check if the tag with the same value exists
    if($TagValueC -eq $currentTag){
        echo "$count. InstanceId: $instance, tag with Key:'Name',Value:'$TagValueC' exists, volumeId: $sda1VolId"
        "$count InstanceId: $instance, tag with Key:'Name',Value:'$TagValueC' exists, volumeId: $sda1VolId" >> sda1Tags.txt
    }
    else{
        #create/replace Tag:Name in the root volume
        aws ec2 create-tags --resources $sda1VolId --tags "Key=Name,Value=$TagValueC"
        "$count. InstanceId: $instance, tag with Key:'Name',Value:'$TagValueC' created, volumeId: $sda1VolId" >> sda1Tags.txt
        echo "$count. InstanceId: $instance, tag with Key:'Name',Value:'$TagValueC' created, volumeId: $sda1VolId"
    }
    #increment the count
    $count++
}


