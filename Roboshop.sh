#!/bin/bash


AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-040370d16c0a7a644"
INSTANCES=("Mongodb" "Mysql" "Redis" "Rabbitmq" "catalogue" "user" "cart" "shipping" 
"payment" "dispatch" "frontend")
ZONE_ID="Z03291968G99ITNDOADC"
DOMAIN_NAME="ravitejauppu.site"



for instance in $@
do
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-040370d16c0a7a644 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId"  --output text)
if [ $instance != "frontend" ]
then 
 IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
 RECORD_NAME="$instance.$DOMAIN_NAME"
else
IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
RECORD_NAME="$DOMAIN_NAME"
fi 
aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'
done