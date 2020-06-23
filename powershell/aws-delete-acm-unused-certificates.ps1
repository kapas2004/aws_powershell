#$regions = (aws ec2 describe-regions --query "Regions[].RegionName" --output text).Split('	')
$regions = ("eu-west-2 eu-west-1 ap-southeast-1 ap-southeast-2 eu-central-1 us-east-1").Split()
foreach($region in $regions) {
    $inUseCount = 0
    $removedCount = 0
    echo "Checking Region $region "
    $certs = (aws acm list-certificates --certificate-statuses --certificate-statuses --region $region --query CertificateSummaryList[].CertificateArn --output text).Split('	')
    foreach($cert in $certs) {
        $certInUse = aws acm describe-certificate --region $region --certificate-arn $cert --query "Certificate.InUseBy[]"
        if($certInUse.Count -le 1){
            echo "remove $cert by uncomment the line below"
            #aws acm delete-certificate --certificate-arn $cert
            $removedCount += 1
        }
        else {
            echo "Certificate in use by:" $certInUse
            $inUseCount += 1
        }
    }
    echo "Total Certs removed $removedCount in the $region region"
    echo "Total Certs in use $inUseCount in the $region region"
}