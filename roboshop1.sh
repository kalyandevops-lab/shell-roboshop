#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0598484c641e7e708" # Replace with your Security Group ID
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z048758535XINF6IZQDEK"
DOMAIN_NAME="daws85s.fun"

for INSTANCE in "${INSTANCES[@]}"
do
  echo "Launching instance: $INSTANCE"

  PRIVATE_IP=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" \
    --query 'Instances[0].PrivateIpAddress' \
    --output text)

  echo "$INSTANCE launched with IP: $PRIVATE_IP"

  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"CREATE\",
        \"ResourceRecordSet\": {
          \"Name\": \"$INSTANCE.$DOMAIN_NAME\",
          \"Type\": \"A\",
          \"TTL\": 300,
          \"ResourceRecords\": [{\"Value\": \"$PRIVATE_IP\"}]
        }
      }]
    }"

  echo "DNS record created for $INSTANCE.$DOMAIN_NAME"
done
