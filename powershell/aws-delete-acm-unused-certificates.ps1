#
# Created by kapas2004
#
# Delete Unused AWS ACM Certificate by iterating all regions
# using mixed powershell and aws cli
# 
#Usage
#.\aws-delete-acm-unused-certificates.ps1
#
# TODO Need fixing if region does not have ACM Certificates hide error and write on console no ACM found
#

$regions = (aws ec2 describe-regions --query "Regions[].RegionName" --output text).Split('	')
foreach($region in $regions) {
    $inUseCount = 0
    $removedCount = 0
    Write-Output "Checking Region $region "
    $certs = (aws acm list-certificates --certificate-statuses --certificate-statuses --region $region --query CertificateSummaryList[].CertificateArn --output text).Split('	')
    foreach($cert in $certs) {
        $certInUse = aws acm describe-certificate --region $region --certificate-arn $cert --query "Certificate.InUseBy[]"
        if($certInUse.Count -le 1){
            Write-Output "remove $cert by uncomment the line below"
            #aws acm delete-certificate --certificate-arn $cert
            $removedCount += 1
        }
        else {
            Write-Output "Certificate in use by:" $certInUse
            $inUseCount += 1
        }
    }
    Write-Output "Total Certs removed $removedCount in the $region region"
    Write-Output "Total Certs in use $inUseCount in the $region region"
}