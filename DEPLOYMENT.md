# AWS EC2 Deployment Guide for Bike Inventory Application

This guide provides step-by-step instructions for deploying the Bike Inventory Application on AWS EC2 using Docker and CI/CD pipelines.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub        │    │   AWS ECR       │    │   AWS EC2       │
│   Repository    │───▶│   Container     │───▶│   Docker        │
│   CI/CD         │    │   Registry      │    │   Container     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   AWS RDS       │
                                               │   MySQL         │
                                               └─────────────────┘
```

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Repository** for your code
3. **AWS CLI** installed and configured
4. **Docker** installed locally (for testing)
5. **Node.js 18+** installed locally

## 🚀 Step-by-Step Deployment Process

### Step 1: AWS Infrastructure Setup

#### 1.1 Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region (us-east-1), and output format (json)
```

#### 1.2 Create AWS Infrastructure
```bash
# Make scripts executable
chmod +x scripts/setup-aws-infrastructure.sh
chmod +x scripts/setup-rds.sh
chmod +x scripts/setup-monitoring.sh

# Run infrastructure setup
./scripts/setup-aws-infrastructure.sh
```

**What this script does:**
- ✅ Creates ECR repository for Docker images
- ✅ Creates EC2 key pair for SSH access
- ✅ Creates security groups with proper firewall rules
- ✅ Creates IAM roles for EC2 with ECR access
- ✅ Launches EC2 instance with Docker pre-installed
- ✅ Outputs all necessary information for next steps

#### 1.3 Create RDS Database
```bash
# Create MySQL database
./scripts/setup-rds.sh
```

**What this script does:**
- ✅ Creates RDS MySQL instance
- ✅ Sets up security groups for database access
- ✅ Configures automated backups and encryption
- ✅ Outputs database connection details

### Step 2: GitHub Repository Setup

#### 2.1 Push Code to GitHub
```bash
git add .
git commit -m "Initial deployment setup"
git push origin main
```

#### 2.2 Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add these secrets:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | `wJalrXUtn...` |
| `EC2_SSH_PRIVATE_KEY` | Content of .pem file | `-----BEGIN RSA PRIVATE KEY-----...` |
| `EC2_HOSTNAME` | EC2 Public IP | `54.123.456.789` |
| `EC2_USER` | EC2 Username | `ec2-user` |
| `DB_HOST` | RDS Endpoint | `bike-inventory-db.xyz.us-east-1.rds.amazonaws.com` |
| `DB_USER` | Database Username | `admin` |
| `DB_PASSWORD` | Database Password | `BikeInventory123!` |
| `DB_NAME` | Database Name | `bike_inventory` |
| `JWT_SECRET` | JWT Secret Key | `your-super-secret-jwt-key-min-32-chars` |

### Step 3: Local Testing

#### 3.1 Test Docker Build
```bash
# Build Docker image locally
docker build -t bike-inventory-app .

# Test with Docker Compose
docker-compose up -d
```

#### 3.2 Run Tests
```bash
# Install dependencies
npm install

# Run tests
npm test
```

### Step 4: Deploy Application

#### 4.1 Trigger Deployment
```bash
# Push to main branch to trigger CI/CD
git push origin main
```

The GitHub Actions workflow will:
1. ✅ Run tests with MySQL database
2. ✅ Build Docker image
3. ✅ Push image to AWS ECR
4. ✅ Deploy to EC2 instance
5. ✅ Start the application container

#### 4.2 Verify Deployment
```bash
# Check application health
curl http://YOUR_EC2_PUBLIC_IP/api/health

# Expected response:
# {
#   "status": "OK",
#   "timestamp": "2024-01-15T10:30:00.000Z",
#   "service": "bike-inventory-api"
# }
```

### Step 5: Set Up Monitoring (Optional but Recommended)

```bash
# Get your EC2 instance ID from the infrastructure setup output
./scripts/setup-monitoring.sh i-1234567890abcdef0

# Subscribe to email alerts
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:bike-inventory-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## 🔧 Configuration Details

### Environment Variables

The application uses these environment variables:

```bash
NODE_ENV=production          # Application environment
PORT=3000                   # Application port
DB_HOST=<rds-endpoint>      # Database host
DB_USER=admin               # Database username
DB_PASSWORD=<password>      # Database password
DB_NAME=bike_inventory      # Database name
JWT_SECRET=<secret>         # JWT signing secret
```

### Security Configuration

#### Firewall Rules (Security Groups)
- **EC2 Security Group**: Allows HTTP (80), HTTPS (443), and SSH (22)
- **RDS Security Group**: Allows MySQL (3306) only from EC2 instances

#### Container Security
- ✅ Runs as non-root user
- ✅ Multi-stage build for minimal attack surface
- ✅ Health checks for container monitoring
- ✅ Resource limits and restart policies

## 📊 Monitoring and Logging

### CloudWatch Integration
- **Metrics**: CPU, Memory, Disk usage
- **Logs**: Application logs in `/aws/ec2/bike-inventory`
- **Alarms**: Automated alerts for high resource usage
- **Dashboard**: Visual monitoring interface

### Application Health Monitoring
- Health check endpoint: `/api/health`
- Container health checks every 30 seconds
- Automatic restart on failure

## 🔄 CI/CD Pipeline Details

### Workflow Triggers
- **Push to main**: Full deployment
- **Push to develop**: Testing only
- **Pull requests**: Testing only

### Pipeline Stages
1. **Test Stage**
   - Sets up MySQL test database
   - Installs dependencies
   - Runs test suite
   - Fails if tests don't pass

2. **Build & Deploy Stage** (main branch only)
   - Builds Docker image
   - Pushes to ECR
   - Deploys to EC2
   - Performs health check

## 🛠️ Maintenance and Updates

### Updating the Application
1. Make code changes
2. Commit and push to main branch
3. CI/CD automatically deploys new version
4. Zero-downtime deployment with health checks

### Database Migrations
```bash
# SSH into EC2 instance
ssh -i bike-inventory-keypair.pem ec2-user@YOUR_EC2_IP

# Run database migrations (if needed)
docker exec -it bike-inventory-app npm run migrate
```

### Backup and Recovery
- **Database**: Automated daily backups (7-day retention)
- **Application Data**: Persistent volumes for uploads and logs
- **Container Images**: Stored in ECR with versioning

## 🚨 Troubleshooting

### Common Issues

#### 1. Deployment Fails
```bash
# Check GitHub Actions logs
# Check EC2 instance logs
ssh -i bike-inventory-keypair.pem ec2-user@YOUR_EC2_IP
docker logs bike-inventory-app
```

#### 2. Database Connection Issues
```bash
# Test database connectivity from EC2
docker exec -it bike-inventory-app npm run db:test
```

#### 3. High Resource Usage
```bash
# Check CloudWatch metrics
# Scale up instance if needed
aws ec2 modify-instance-attribute --instance-id i-1234567890abcdef0 --instance-type t3.small
```

### Useful Commands

```bash
# View application logs
docker logs -f bike-inventory-app

# Restart application
docker restart bike-inventory-app

# Update application manually
docker pull YOUR_ECR_URI:latest
docker stop bike-inventory-app
docker rm bike-inventory-app
docker run -d --name bike-inventory-app [previous run command]

# Check resource usage
docker stats bike-inventory-app
```

## 💰 Cost Optimization

### AWS Resources and Estimated Monthly Costs
- **EC2 t3.micro**: ~$8.50/month
- **RDS db.t3.micro**: ~$12.60/month  
- **ECR storage**: ~$1/month for 1GB
- **Data transfer**: ~$2-5/month
- **CloudWatch**: ~$1-3/month

**Total estimated cost**: ~$25-30/month

### Cost Optimization Tips
1. Use Reserved Instances for production (up to 75% savings)
2. Enable RDS auto-scaling
3. Set up CloudWatch billing alerts
4. Clean up old ECR images regularly

## 🔐 Security Best Practices

### Implemented Security Measures
- ✅ VPC with private subnets for RDS
- ✅ Security groups with minimal required access
- ✅ IAM roles with least privilege principle
- ✅ Encrypted RDS storage
- ✅ Container runs as non-root user
- ✅ Environment variables for sensitive data

### Additional Recommendations
1. Enable AWS CloudTrail for audit logging
2. Set up AWS Config for compliance monitoring
3. Use AWS Secrets Manager for sensitive credentials
4. Enable MFA for AWS root account
5. Regular security updates for EC2 instances

## 📞 Support and Maintenance

### Regular Maintenance Tasks
- [ ] Weekly: Review CloudWatch metrics and logs
- [ ] Monthly: Update dependencies and security patches
- [ ] Quarterly: Review and optimize costs
- [ ] Yearly: Security audit and compliance review

### Getting Help
1. Check CloudWatch logs and metrics
2. Review GitHub Actions workflow logs
3. SSH into EC2 instance for debugging
4. Use AWS Support for infrastructure issues

---

## 🎉 Congratulations!

Your Bike Inventory Application is now successfully deployed on AWS with:
- ✅ Automated CI/CD pipeline
- ✅ Containerized deployment with Docker
- ✅ Scalable and secure infrastructure
- ✅ Monitoring and alerting
- ✅ Database with automated backups

Your application is accessible at: `http://YOUR_EC2_PUBLIC_IP/api/health`