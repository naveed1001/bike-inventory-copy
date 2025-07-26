#!/bin/bash

# ------------------------------------------
# AWS RDS Setup Script for Bike Inventory App
# Creates a MySQL RDS instance with secure defaults
# ------------------------------------------

set -e

# Configuration (values injected via GitHub Actions secrets or exported shell env)
REGION="us-east-1"
DB_INSTANCE_IDENTIFIER="bike-inventory-db"
DB_NAME="bike_inventory"
DB_USERNAME="${DB_USERNAME:-admin}"  # fallback to 'admin' if not set
DB_PASSWORD="${DB_PASSWORD:?DB_PASSWORD}"  # will error if unset
DB_INSTANCE_CLASS="db.t3.micro"
ALLOCATED_STORAGE="20"
SECURITY_GROUP_NAME="bike-inventory-db-sg"
SUBNET_GROUP_NAME="bike-inventory-subnet-group"

echo "🗄️ Starting RDS setup for Bike Inventory..."

# Step 1: Create Security Group
echo "🛡️ Creating DB Security Group..."
DB_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name "$SECURITY_GROUP_NAME" \
  --description "Security group for Bike Inventory DB" \
  --region "$REGION" \
  --query 'GroupId' --output text)

# Add MySQL port access from EC2 SG
EC2_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=bike-inventory-sg" \
  --region "$REGION" \
  --query 'SecurityGroups[0].GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$DB_SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 3306 \
  --source-group "$EC2_SECURITY_GROUP_ID" \
  --region "$REGION"

echo "✅ Security group created: $DB_SECURITY_GROUP_ID"

# Step 2: Create DB Subnet Group
echo "📡 Creating DB Subnet Group..."

VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --region "$REGION" \
  --query 'Vpcs[0].VpcId' --output text)

SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'Subnets[0:2].SubnetId' --output text)

SUBNET_ARRAY=($SUBNET_IDS)

aws rds create-db-subnet-group \
  --db-subnet-group-name "$SUBNET_GROUP_NAME" \
  --db-subnet-group-description "Subnet group for Bike Inventory DB" \
  --subnet-ids "${SUBNET_ARRAY[@]}" \
  --region "$REGION" || echo "Subnet group may already exist"

# Step 3: Create RDS MySQL Instance
echo "🗄️ Creating RDS MySQL instance..."
aws rds create-db-instance \
  --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
  --db-instance-class "$DB_INSTANCE_CLASS" \
  --engine mysql \
  --engine-version "8.0" \
  --master-username "$DB_USERNAME" \
  --master-user-password "$DB_PASSWORD" \
  --allocated-storage "$ALLOCATED_STORAGE" \
  --db-name "$DB_NAME" \
  --vpc-security-group-ids "$DB_SECURITY_GROUP_ID" \
  --db-subnet-group-name "$SUBNET_GROUP_NAME" \
  --backup-retention-period 7 \
  --storage-encrypted \
  --multi-az false \
  --publicly-accessible false \
  --auto-minor-version-upgrade true \
  --region "$REGION" \
  --tags Key=Name,Value=BikeInventoryDatabase

echo "⏳ Waiting for RDS instance to become available..."
aws rds wait db-instance-available \
  --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
  --region "$REGION"

# Step 4: Fetch RDS Endpoint
DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_INSTANCE_IDENTIFIER" \
  --region "$REGION" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

# Summary
echo ""
echo "🎉 RDS setup complete!"
echo "📋 Database Details:"
echo "  DB Identifier : $DB_INSTANCE_IDENTIFIER"
echo "  Endpoint      : $DB_ENDPOINT"
echo "  DB Name       : $DB_NAME"
echo "  Username      : $DB_USERNAME"
echo "  Password      : $DB_PASSWORD"
echo "  Security Group: $DB_SECURITY_GROUP_ID"
echo ""
echo "🔧 Next Steps:"
echo "1. Update GitHub Secrets with:"
echo "   - DB_HOST=$DB_ENDPOINT"
echo "   - DB_USER=$DB_USERNAME"
echo "   - DB_PASSWORD=$DB_PASSWORD"
echo "   - DB_NAME=$DB_NAME"
echo ""
echo "2. The DB is private and only accessible from the EC2 instance."
echo "3. 🚨 Change the default DB password in production environments!"
echo ""
echo "✅ RDS setup completed successfully!"