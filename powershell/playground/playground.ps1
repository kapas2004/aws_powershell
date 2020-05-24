$instances = (aws ec2 describe-instances--query "Reservations[].Instances[].InstanceId" --output text).split()

#search for a tag called Name in volume /dev/sda1
echo "tagNameInstance, instance, tagNameVol" > hasatag.csv
echo "tagNameInstance, instance, tagNameVol" > hasnottag.csv
foreach($instance in $instances) {
    $tagNameInstance= aws ec2 describe-instances --instance-ids $instance --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value] | [0]" --output text
    #search
    #Windows instances
    $tagNameVol = aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instance Name=attachment.device,Values='/dev/sda1' --query "Volumes[].[Tags[?Key=='Name'].Value] | [0]" --output text
    #Linux instances
    #$tagNameVol = aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$instance Name=attachment.device,Values='/dev/xvda' --query "Volumes[].[Tags[?Key=='Name'].Value] | [0]" --output text
    if((-not ([string]::IsNullOrEmpty($tagNameVol))) -and ($tagNameVol -ne 'None')){
        echo "$tagNameInstance,$instance,$tagNameVol" >> hasatag.csv
        echo "Instance $tagNameInstance with Id= $instance  has a Tag:Name=$tagNameVol on /dev/sda1"
    }
    else {
        echo "$tagNameInstance,$instance,$tagNameVol" >> hasnottag.csv
        echo "Instance $tagNameInstance with Id= $instance  does not have a Tag:Name on /dev/sda1"
    }

    #add Tag Key=Name,Value=TagInstanceName (C)
    #aws ec2-create-tags --resources $volume --tags Key=Name,Value=$tagNameInstance
    #vol-0abcf8a19eaffe379
    #UKASVARNISH-ExCel-ASG
    
    #create/replace tags
    #aws ec2 create-tags --resources "vol-0abcf8a19eaffe379" --tags Key=Name,Value="UKASVARNISH-ExCel-ASG" Key=AWSBackup,Value="App Server"
    #delete tags
    #aws ec2 delete-tags --resources "vol-0abcf8a19eaffe379" --tags Key=AWSBackup,Value="App Server"
}
 
#i-0ea5a88816f012ef0


aws ec2 describe-instances --instance-ids i-0e4894bcdea4f5b4e --filters Name=block-device-mapping.device-name,Values=/dev/sda1 --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value]" --output text
