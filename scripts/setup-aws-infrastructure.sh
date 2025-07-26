#!/bin/bash

# Exit on error
set -e

echo "⚙️ Setting up AWS infrastructure..."

# AWS configuration
REGION="us-east-1"
ECR_REPO_NAME="bike-inventory-app"
KEY_PAIR_NAME="bike-inventory-key"
INSTANCE_ID="i-05075a302647e30ba"
EC2_PUBLIC_IP="50.16.77.27"

# Fetch the security group ID from the existing instance
SECURITY_GROUP_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

# 1. Authenticate AWS CLI
aws configure set default.region $REGION

# 2. Create ECR Repository (safe to rerun)
echo "📦 Creating ECR repository..."
aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" > /dev/null 2>&1 || \
aws ecr create-repository --repository-name "$ECR_REPO_NAME"

# 3. Skip EC2 Key Pair (already exists)
echo "🔑 Skipping Key Pair creation. Using existing: $KEY_PAIR_NAME"

# 4. Security Group already exists
echo "🛡️ Using Security Group ID: $SECURITY_GROUP_ID"

# 5. EC2 Instance already exists
echo "💻 Using EC2 Instance ID: $INSTANCE_ID"

# 6. Output GitHub Actions secrets template
echo ""
echo "✅ AWS infrastructure is ready!"
echo ""
echo "👉 Set the following GitHub Secrets:"
echo "-----------------------------------------------"
echo "EC2_SSH_PRIVATE_KEY: <your-private-key-content>"
echo "EC2_HOSTNAME: $EC2_PUBLIC_IP"
echo "EC2_USER: ec2-user"
echo "-----------------------------------------------"














# #!/bin/bash

# # AWS Infrastructure Setup Script for Bike Inventory Application
# # This script creates all necessary AWS resources for deployment

# set -e

# # Configuration
# REGION="us-east-1"
# ECR_REPO_NAME="bike-inventory-app"
# KEY_PAIR_NAME="bike-inventory-keypair"
# SECURITY_GROUP_NAME="bike-inventory-sg"
# INSTANCE_TYPE="t3.micro"
# AMI_ID="ami-08a6efd148b1f7504" # Amazon Linux 2 AMI (update as needed)

# echo "🚀 Setting up AWS infrastructure for Bike Inventory Application..."

# # 1. Create ECR Repository
# echo "📦 Creating ECR repository..."
# aws ecr create-repository \
#     --repository-name $ECR_REPO_NAME \
#     --region $REGION \
#     --image-scanning-configuration scanOnPush=true \
#     --encryption-configuration encryptionType=AES256 || echo "Repository may already exist"

# # 2. Create Key Pair
# echo "🔑 Creating EC2 Key Pair..."
# aws ec2 create-key-pair \
#     --key-name $KEY_PAIR_NAME \
#     --region $REGION \
#     --query 'KeyMaterial' \
#     --output text > ${KEY_PAIR_NAME}.pem

# chmod 400 ${KEY_PAIR_NAME}.pem
# echo "✅ Key pair saved as ${KEY_PAIR_NAME}.pem"

# # 3. Create Security Group
# echo "🛡️ Creating Security Group..."
# SECURITY_GROUP_ID=$(aws ec2 create-security-group \
#     --group-name $SECURITY_GROUP_NAME \
#     --description "Security group for Bike Inventory Application" \
#     --region $REGION \
#     --query 'GroupId' \
#     --output text)

# # Add inbound rules
# aws ec2 authorize-security-group-ingress \
#     --group-id $SECURITY_GROUP_ID \
#     --protocol tcp \
#     --port 22 \
#     --cidr 0.0.0.0/0 \
#     --region $REGION

# aws ec2 authorize-security-group-ingress \
#     --group-id $SECURITY_GROUP_ID \
#     --protocol tcp \
#     --port 80 \
#     --cidr 0.0.0.0/0 \
#     --region $REGION

# aws ec2 authorize-security-group-ingress \
#     --group-id $SECURITY_GROUP_ID \
#     --protocol tcp \
#     --port 443 \
#     --cidr 0.0.0.0/0 \
#     --region $REGION

# echo "✅ Security Group created: $SECURITY_GROUP_ID"

# # 4. Create IAM Role for EC2
# echo "👤 Creating IAM Role for EC2..."
# cat > trust-policy.json << EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF

# aws iam create-role \
#     --role-name BikeInventoryEC2Role \
#     --assume-role-policy-document file://trust-policy.json || echo "Role may already exist"

# # Attach ECR policy
# aws iam attach-role-policy \
#     --role-name BikeInventoryEC2Role \
#     --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# # Create instance profile
# aws iam create-instance-profile \
#     --instance-profile-name BikeInventoryEC2Profile || echo "Profile may already exist"

# aws iam add-role-to-instance-profile \
#     --instance-profile-name BikeInventoryEC2Profile \
#     --role-name BikeInventoryEC2Role || echo "Role may already be added"

# # 5. Create User Data Script
# cat > user-data.sh << 'EOF'
# #!/bin/bash
# yum update -y
# yum install -y docker aws-cli

# # Start Docker
# systemctl start docker
# systemctl enable docker
# usermod -a -G docker ec2-user

# # Create directories for persistent data
# mkdir -p /home/ec2-user/uploads
# mkdir -p /home/ec2-user/logs
# chown ec2-user:ec2-user /home/ec2-user/uploads /home/ec2-user/logs

# # Install Docker Compose
# curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose
# EOF

# # 6. Launch EC2 Instance
# echo "🖥️ Launching EC2 instance..."
# INSTANCE_ID=$(aws ec2 run-instances \
#     --image-id $AMI_ID \
#     --count 1 \
#     --instance-type $INSTANCE_TYPE \
#     --key-name $KEY_PAIR_NAME \
#     --security-group-ids $SECURITY_GROUP_ID \
#     --iam-instance-profile Name=BikeInventoryEC2Profile \
#     --user-data file://user-data.sh \
#     --region $REGION \
#     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=BikeInventoryApp}]' \
#     --query 'Instances[0].InstanceId' \
#     --output text)

# echo "✅ EC2 Instance launched: $INSTANCE_ID"

# # Wait for instance to be running
# echo "⏳ Waiting for instance to be running..."
# aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# # Get public IP
# PUBLIC_IP=$(aws ec2 describe-instances \
#     --instance-ids $INSTANCE_ID \
#     --region $REGION \
#     --query 'Reservations[0].Instances[0].PublicIpAddress' \
#     --output text)

# echo "🎉 Infrastructure setup complete!"
# echo ""
# echo "📋 Summary:"
# echo "  ECR Repository: $ECR_REPO_NAME"
# echo "  EC2 Instance ID: $INSTANCE_ID"
# echo "  Public IP: $PUBLIC_IP"
# echo "  Security Group: $SECURITY_GROUP_ID"
# echo "  Key Pair: ${KEY_PAIR_NAME}.pem"
# echo ""
# echo "🔧 Next Steps:"
# echo "1. Set up GitHub Secrets with the following values:"
# echo "   - AWS_ACCESS_KEY_ID: Your AWS Access Key"
# echo "   - AWS_SECRET_ACCESS_KEY: Your AWS Secret Key"
# echo "   - EC2_SSH_PRIVATE_KEY: Content of ${KEY_PAIR_NAME}.pem"
# echo "   - EC2_HOSTNAME: $PUBLIC_IP"
# echo "   - EC2_USER: ec2-user"
# echo "   - DB_HOST: Your RDS endpoint"
# echo "   - DB_USER: Your database username"
# echo "   - DB_PASSWORD: Your database password"
# echo "   - DB_NAME: bike_inventory"
# echo "   - JWT_SECRET: Your JWT secret key"
# echo ""
# echo "2. Create RDS MySQL instance (see setup-rds.sh)"
# echo "3. Push your code to GitHub main branch to trigger deployment"

# # Cleanup temporary files
# rm -f trust-policy.json user-data.sh

# echo "✨ Setup script completed successfully!"