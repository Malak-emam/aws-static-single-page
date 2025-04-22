#!/bin/bash
# AWS Static Website Setup with CloudFront (One-Time Script)
BUCKET="malak-website"
REGION="us-east-1"
HTML_FILE="index.html"

# Create S3 bucket and enable static hosting
echo "Creating S3 bucket and configuring static website..."
aws s3 mb s3://$BUCKET --region $REGION
aws s3 website s3://$BUCKET --index-document $HTML_FILE

# Upload index.html
echo "Uploading $HTML_FILE..."
aws s3 cp $HTML_FILE s3://$BUCKET/

# Create CloudFront OAC (Origin Access Control)
echo "Creating CloudFront distribution (this may take 5-10 mins)..."
DISTRIBUTION_JSON=$(aws cloudfront create-distribution \
  --origin-domain-name "$BUCKET.s3.amazonaws.com" \
  --default-root-object $HTML_FILE \
  --origins '[
    {
      "Id": "S3Origin",
      "DomainName": "'$BUCKET'.s3.amazonaws.com",
      "S3OriginConfig": { "OriginAccessIdentity": "" }
    }
  ]' \
  --default-cache-behavior '{
    "TargetOriginId": "S3Origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized policy
  }' \
  --enabled)

# Extract Distribution ID
DISTRIBUTION_ID=$(echo $DISTRIBUTION_JSON | jq -r '.Distribution.Id')
echo "CloudFront Distribution ID: $DISTRIBUTION_ID"

# Create OAC and update S3 policy
echo "Configuring Origin Access Control..."
OAC_JSON=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config '{
    "Name": "MyOAC",
    "OriginAccessControlOriginType": "s3",
    "SigningBehavior": "never",
    "SigningProtocol": "sigv4"
  }')

OAC_ID=$(echo $OAC_JSON | jq -r '.OriginAccessControl.Id')

# Update CloudFront with OAC
aws cloudfront update-distribution \
  --id $DISTRIBUTION_ID \
  --distribution-config '{
    "Origins": {
      "Items": [
        {
          "Id": "S3Origin",
          "DomainName": "'$BUCKET'.s3.amazonaws.com",
          "OriginAccessControlId": "'$OAC_ID'",
          "S3OriginConfig": { "OriginAccessIdentity": "" }
        }
      ],
      "Quantity": 1
    },
    "DefaultCacheBehavior": {
      "TargetOriginId": "S3Origin",
      "ViewerProtocolPolicy": "redirect-to-https",
      "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6"
    },
    "Enabled": true
  }'

# Generate S3 bucket policy
echo "Updating S3 bucket policy..."
aws s3api put-bucket-policy \
  --bucket $BUCKET \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowCloudFront",
        "Effect": "Allow",
        "Principal": { "Service": "cloudfront.amazonaws.com" },
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::'$BUCKET'/*",
        "Condition": {
          "StringEquals": {
            "AWS:SourceArn": "arn:aws:cloudfront::'$(aws sts get-caller-identity --query Account --output text)':distribution/'$DISTRIBUTION_ID'"
          }
        }
      }
    ]
  }'

echo "--------------------------------------------------"
echo "Setup Complete!"
echo "CloudFront URL: https://$(echo $DISTRIBUTION_JSON | jq -r '.Distribution.DomainName')"
echo "S3 Website URL (blocked): http://$BUCKET.s3-website-$REGION.amazonaws.com"
echo "--------------------------------------------------"
