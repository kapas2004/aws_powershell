#
# List of manually added general instance types not running for cost optimization
# using mixed powershell and aws cli
# 
#Usage
#.\count_stopped_instance_type_for_cost_optimization.ps1
#

$state = "stopped"
$region = "eu-west-2"
$instance_types = "m4", "t3a", "t3a", "t2", "r5a", "r5", "r4", "m5a", "m5", "m4", "c5d", "c5"

if($state -eq "stopped"){
    Write-Output "Instance types stopped:"
}

if($state -eq "running"){
    Write-Output "Instance types running:"
}

foreach($instance_type in $instance_types) {
    $count = `
    aws ec2 describe-instances `
        --region $region `
        --filters "Name=instance-state-name,Values=$state" "Name=instance-type,Values=$instance_type.*" `
        --query "Reservations[].Instances[].[InstanceId] | length(@)" `
        --output text

    if($count -ne 0){
        
        Write-Output "$instance_type, $count"
        "$instance_type, $count" >> "$region-$state.csv"
    }
}