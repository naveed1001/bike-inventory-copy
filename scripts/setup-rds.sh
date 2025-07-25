#!/bin/bash

# AWS RDS Setup Script for Bike Inventory Application
# This script creates a MySQL RDS instance

set -e

# Configuration
REGION="us-east-1"
DB_INSTANCE_IDENTIFIER="bike-inventory-db"
DB_NAME="bike_inventory"
DB_USERNAME="admin"
DB_PASSWORD="BikeInventory123!" # Change this to a secure password
DB_INSTANCE_CLASS="db.t3.micro"
ALLOCATED_STORAGE="20"
SECURITY_GROUP_NAME="bike-inventory-db-sg"

echo "🗄️ Setting up RDS MySQL database for Bike Inventory Application..."

# 1. Create DB Security Group
echo "🛡️ Creating Database Security Group..."
DB_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for Bike Inventory Database" \
    --region $REGION \
    --query 'GroupId' \
    --output text)

# Add inbound rule for MySQL (port 3306) from EC2 security group
EC2_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=bike-inventory-sg" \
    --region $REGION \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $DB_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 3306 \
    --source-group $EC2_SECURITY_GROUP_ID \
    --region $REGION

echo "✅ Database Security Group created: $DB_SECURITY_GROUP_ID"

# 2. Create DB Subnet Group
echo "📡 Creating DB Subnet Group..."
# Get default VPC
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --region $REGION \
    --query 'Vpcs[0].VpcId' \
    --output text)

# Get subnets in different AZs
SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --region $REGION \
    --query 'Subnets[0:2].SubnetId' \
    --output text)

SUBNET_ARRAY=($SUBNET_IDS)

aws rds create-db-subnet-group \
    --db-subnet-group-name bike-inventory-subnet-group \
    --db-subnet-group-description "Subnet group for Bike Inventory Database" \
    --subnet-ids ${SUBNET_ARRAY[0]} ${SUBNET_ARRAY[1]} \
    --region $REGION || echo "Subnet group may already exist"

# 3. Create RDS Instance
echo "🗄️ Creating RDS MySQL instance..."
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine mysql \
    --engine-version "8.0" \
    --master-username $DB_USERNAME \
    --master-user-password $DB_PASSWORD \
    --allocated-storage $ALLOCATED_STORAGE \
    --db-name $DB_NAME \
    --vpc-security-group-ids $DB_SECURITY_GROUP_ID \
    --db-subnet-group-name bike-inventory-subnet-group \
    --backup-retention-period 7 \
    --storage-encrypted \
    --multi-az false \
    --publicly-accessible false \
    --auto-minor-version-upgrade true \
    --region $REGION \
    --tags Key=Name,Value=BikeInventoryDatabase

echo "✅ RDS instance creation initiated: $DB_INSTANCE_IDENTIFIER"

# 4. Wait for DB instance to be available
echo "⏳ Waiting for RDS instance to be available (this may take 10-15 minutes)..."
aws rds wait db-instance-available \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --region $REGION

# 5. Get DB endpoint
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --region $REGION \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "🎉 RDS setup complete!"
echo ""
echo "📋 Database Details:"
echo "  Instance Identifier: $DB_INSTANCE_IDENTIFIER"
echo "  Endpoint: $DB_ENDPOINT"
echo "  Database Name: $DB_NAME"
echo "  Username: $DB_USERNAME"
echo "  Password: $DB_PASSWORD"
echo "  Security Group: $DB_SECURITY_GROUP_ID"
echo ""
echo "🔧 Important:"
echo "1. Update your GitHub Secrets with:"
echo "   - DB_HOST: $DB_ENDPOINT"
echo "   - DB_USER: $DB_USERNAME"
echo "   - DB_PASSWORD: $DB_PASSWORD"
echo "   - DB_NAME: $DB_NAME"
echo ""
echo "2. The database is only accessible from your EC2 instance for security."
echo "3. Make sure to change the default password in production!"
echo ""
echo "✨ RDS setup completed successfully!"