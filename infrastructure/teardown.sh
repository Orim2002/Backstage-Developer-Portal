#!/bin/bash

set -e

REGION="us-east-1"
BUCKET_NAME="backstage-tfstate-orima"
DYNAMODB_TABLE="terraform-state-lock"
ECR_REPO="dev-backstage"
ECS_CLUSTER="dev-backstage-cluster"

echo "WARNING: This will destroy ALL Backstage infrastructure!"
echo "This includes: ECS, RDS, ALB, VPC, ECR, Secrets, and Terraform state backend."
read -p "Are you sure? Type 'yes' to continue: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "Step 1/4: Deleting ECR repository..."
aws ecr delete-repository \
  --repository-name $ECR_REPO \
  --region $REGION \
  --force || echo "ECR repo already deleted or not found"

echo ""
echo "Step 2/4: Deleting Secrets Manager secrets..."
for SECRET in backstage/db-password backstage/github-token backstage/github-client-id backstage/github-client-secret; do
  aws secretsmanager delete-secret \
    --secret-id $SECRET \
    --force-delete-without-recovery \
    --region $REGION 2>/dev/null || echo "Secret $SECRET not found, skipping"
done

echo ""
echo "Step 3/4: Deleting Terraform state S3 bucket..."
aws s3 rm s3://$BUCKET_NAME --recursive || echo "Bucket already empty"
aws s3api delete-bucket-versioning \
  --bucket $BUCKET_NAME || echo "Could not disable versioning"

VERSIONS=$(aws s3api list-object-versions --bucket $BUCKET_NAME 2>/dev/null)
if [ -n "$VERSIONS" ]; then
  aws s3api delete-objects \
    --bucket $BUCKET_NAME \
    --delete "$(echo $VERSIONS | python3 -c "
import sys, json
v = json.load(sys.stdin)
objects = [{'Key': o['Key'], 'VersionId': o['VersionId']} for o in v.get('Versions', [])]
objects += [{'Key': o['Key'], 'VersionId': o['VersionId']} for o in v.get('DeleteMarkers', [])]
print(json.dumps({'Objects': objects}))
")" 2>/dev/null || echo "No versions to delete"
fi

aws s3api delete-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION || echo "Bucket already deleted"

echo ""
echo "Step 4/4: Deleting DynamoDB state lock table..."
aws dynamodb delete-table \
  --table-name $DYNAMODB_TABLE \
  --region $REGION || echo "DynamoDB table already deleted or not found"

echo ""
echo "Teardown complete! All Backstage infrastructure has been destroyed."