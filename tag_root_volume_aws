#Add Tag Name to all Windows platform root volumes same as the Instance Name Tag plus (C) accross region

$region = "eu-west-2"
#Get all instances in one region
$instances = (aws ec2 describe-instances --filter Name=platform,Values=windows --region $region --query "Reservations[].Instances[].InstanceId" --output text).split()

$count = 1
$temp1 ="Total Number of Instances contain /dev/sda1 volume: " + $instances.Count
$temp1  > sda1Tags.txt
echo $temp1
foreach($instance in $instances) {
    
    #get the volumeId and Instance Tag:Name
    $TagValue = aws ec2 describe-instances --instance-ids $instance --filters Name=block-device-mapping.device-name,Values=/dev/sda1 --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value]" --output text
    $sda1VolId = aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instance Name=attachment.device,Values=/dev/sda1 --query "Volumes[].Attachments[].VolumeId" --output text    
    $currentTag = aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instance Name=attachment.device,Values=/dev/sda1 --query "Volumes[].Tags[?Key=='Name'].Value" --output text
    
    #put Instance Tag:Name in a separate variable
    $TagValueC = $TagValue + " (C)"
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
    $count++
}
