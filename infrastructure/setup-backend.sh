#!/bin/bash

set -e

REGION="us-east-1"
BUCKET_NAME="backstage-tfstate-orima"
DYNAMODB_TABLE="terraform-state-lock"

echo "Creating S3 bucket for Terraform state..."
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION

echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

echo "Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "Creating DynamoDB table for state locking..."
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

echo "Backend setup complete!"
echo "Bucket: $BUCKET_NAME"
echo "DynamoDB: $DYNAMODB_TABLE"