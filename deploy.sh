#!/bin/bash

# Master Deployment Script for Bike Inventory Application
# This script orchestrates the complete deployment process

set -e

echo "🚀 Starting Bike Inventory Application Deployment"
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Menu function
show_menu() {
    echo ""
    echo "What would you like to do?"
    echo "1) 🏗️  Set up AWS Infrastructure (ECR, EC2, Security Groups)"
    echo "2) 🗄️  Set up RDS Database"
    echo "3) 📊 Set up Monitoring (CloudWatch, Alarms)"
    echo "4) 🧪 Test Docker Build Locally"
    echo "5) 🚀 Complete Setup (Infrastructure + Database + Monitoring)"
    echo "6) 📋 Show GitHub Secrets Template"
    echo "7) ❓ Show Help"
    echo "8) 🚪 Exit"
    echo ""
    read -p "Enter your choice (1-8): " choice
}

# Setup infrastructure
setup_infrastructure() {
    print_status "Setting up AWS Infrastructure..."
    if [ -f "scripts/setup-aws-infrastructure.sh" ]; then
        ./scripts/setup-aws-infrastructure.sh
        print_success "Infrastructure setup completed!"
    else
        print_error "Infrastructure script not found!"
        exit 1
    fi
}

# Setup database
setup_database() {
    print_status "Setting up RDS Database..."
    if [ -f "scripts/setup-rds.sh" ]; then
        ./scripts/setup-rds.sh
        print_success "Database setup completed!"
    else
        print_error "Database script not found!"
        exit 1
    fi
}

# Setup monitoring
setup_monitoring() {
    print_status "Setting up Monitoring..."
    read -p "Enter your EC2 Instance ID: " instance_id
    if [ -f "scripts/setup-monitoring.sh" ]; then
        ./scripts/setup-monitoring.sh "$instance_id"
        print_success "Monitoring setup completed!"
    else
        print_error "Monitoring script not found!"
        exit 1
    fi
}

# Test Docker build
test_docker() {
    print_status "Testing Docker build..."
    
    # Build Docker image
    docker build -t bike-inventory-app .
    print_success "Docker image built successfully!"
    
    # Test with docker-compose
    print_status "Testing with Docker Compose..."
    docker-compose up -d
    
    # Wait for containers to start
    sleep 10
    
    # Test health endpoint
    if curl -f http://localhost:3000/api/health &> /dev/null; then
        print_success "Application is running and healthy!"
    else
        print_warning "Health check failed, but containers are running"
    fi
    
    # Stop containers
    docker-compose down
    print_success "Docker test completed!"
}

# Complete setup
complete_setup() {
    print_status "Running complete setup..."
    setup_infrastructure
    echo ""
    setup_database
    echo ""
    print_status "Please get your EC2 Instance ID from the infrastructure output above"
    read -p "Enter your EC2 Instance ID: " instance_id
    ./scripts/setup-monitoring.sh "$instance_id"
    print_success "Complete setup finished!"
}

# Show GitHub secrets template
show_github_secrets() {
    echo ""
    echo "📋 GitHub Secrets Configuration"
    echo "================================"
    echo ""
    echo "Go to your GitHub repository → Settings → Secrets and variables → Actions"
    echo "Add the following secrets:"
    echo ""
    echo "| Secret Name              | Description           | Get Value From        |"
    echo "|--------------------------|----------------------|----------------------|"
    echo "| AWS_ACCESS_KEY_ID        | AWS Access Key       | AWS Console          |"
    echo "| AWS_SECRET_ACCESS_KEY    | AWS Secret Key       | AWS Console          |"
    echo "| EC2_SSH_PRIVATE_KEY      | SSH Private Key      | Infrastructure output|"
    echo "| EC2_HOSTNAME             | EC2 Public IP        | Infrastructure output|"
    echo "| EC2_USER                 | EC2 Username         | ec2-user             |"
    echo "| DB_HOST                  | RDS Endpoint         | Database output      |"
    echo "| DB_USER                  | Database Username    | Database output      |"
    echo "| DB_PASSWORD              | Database Password    | Database output      |"
    echo "| DB_NAME                  | Database Name        | bike_inventory       |"
    echo "| JWT_SECRET               | JWT Secret Key       | Generate secure key  |"
    echo ""
    echo "💡 Tip: Generate a secure JWT secret with:"
    echo "   node -e \"console.log(require('crypto').randomBytes(64).toString('hex'))\""
    echo ""
}

# Show help
show_help() {
    echo ""
    echo "🆘 Help - Bike Inventory Deployment"
    echo "===================================="
    echo ""
    echo "This script helps you deploy the Bike Inventory Application to AWS EC2."
    echo ""
    echo "Prerequisites:"
    echo "- AWS Account with appropriate permissions"
    echo "- AWS CLI installed and configured"
    echo "- Docker installed"
    echo "- GitHub repository for your code"
    echo ""
    echo "Deployment Process:"
    echo "1. Run option 5 for complete setup"
    echo "2. Configure GitHub Secrets (option 6)"
    echo "3. Push code to GitHub main branch"
    echo "4. GitHub Actions will automatically deploy"
    echo ""
    echo "For detailed instructions, see DEPLOYMENT.md"
    echo ""
}

# Main execution
main() {
    echo "🚴‍♂️ Bike Inventory Application Deployment Tool"
    echo ""
    
    check_prerequisites
    
    while true; do
        show_menu
        
        case $choice in
            1)
                setup_infrastructure
                ;;
            2)
                setup_database
                ;;
            3)
                setup_monitoring
                ;;
            4)
                test_docker
                ;;
            5)
                complete_setup
                ;;
            6)
                show_github_secrets
                ;;
            7)
                show_help
                ;;
            8)
                print_success "Goodbye! 👋"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-8."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main