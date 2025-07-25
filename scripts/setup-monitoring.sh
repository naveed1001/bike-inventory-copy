#!/bin/bash

# AWS CloudWatch Monitoring Setup Script
# This script sets up monitoring and alerting for the Bike Inventory Application

set -e

REGION="us-east-1"
INSTANCE_ID=$1

if [ -z "$INSTANCE_ID" ]; then
    echo "Usage: $0 <instance-id>"
    echo "Please provide the EC2 instance ID"
    exit 1
fi

echo "📊 Setting up CloudWatch monitoring for instance: $INSTANCE_ID"

# 1. Create CloudWatch Log Group
echo "📝 Creating CloudWatch Log Group..."
aws logs create-log-group \
    --log-group-name /aws/ec2/bike-inventory \
    --region $REGION || echo "Log group may already exist"

# Set retention policy
aws logs put-retention-policy \
    --log-group-name /aws/ec2/bike-inventory \
    --retention-in-days 30 \
    --region $REGION

# 2. Create SNS Topic for Alerts
echo "🔔 Creating SNS topic for alerts..."
SNS_TOPIC_ARN=$(aws sns create-topic \
    --name bike-inventory-alerts \
    --region $REGION \
    --query 'TopicArn' \
    --output text)

echo "✅ SNS Topic created: $SNS_TOPIC_ARN"

# 3. Create CloudWatch Alarms
echo "⚠️ Creating CloudWatch alarms..."

# CPU Utilization Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "BikeInventory-HighCPU" \
    --alarm-description "Alarm when CPU exceeds 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $SNS_TOPIC_ARN \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --region $REGION

# Memory Utilization Alarm (requires CloudWatch agent)
aws cloudwatch put-metric-alarm \
    --alarm-name "BikeInventory-HighMemory" \
    --alarm-description "Alarm when memory usage exceeds 85%" \
    --metric-name MemoryUtilization \
    --namespace CWAgent \
    --statistic Average \
    --period 300 \
    --threshold 85 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $SNS_TOPIC_ARN \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --region $REGION

# Disk Space Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "BikeInventory-LowDiskSpace" \
    --alarm-description "Alarm when disk usage exceeds 90%" \
    --metric-name DiskSpaceUtilization \
    --namespace CWAgent \
    --statistic Average \
    --period 300 \
    --threshold 90 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --alarm-actions $SNS_TOPIC_ARN \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --region $REGION

# Application Health Check Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "BikeInventory-HealthCheck" \
    --alarm-description "Alarm when health check fails" \
    --metric-name StatusCheckFailed \
    --namespace AWS/EC2 \
    --statistic Maximum \
    --period 60 \
    --threshold 0 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $SNS_TOPIC_ARN \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --region $REGION

echo "✅ CloudWatch alarms created"

# 4. Create CloudWatch Dashboard
echo "📈 Creating CloudWatch dashboard..."
cat > dashboard.json << EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "InstanceId", "$INSTANCE_ID" ]
                ],
                "period": 300,
                "stat": "Average",
                "region": "$REGION",
                "title": "EC2 Instance CPU Utilization"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "CWAgent", "MemoryUtilization", "InstanceId", "$INSTANCE_ID" ]
                ],
                "period": 300,
                "stat": "Average",
                "region": "$REGION",
                "title": "Memory Utilization"
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 6,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/aws/ec2/bike-inventory'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 100",
                "region": "$REGION",
                "title": "Application Logs"
            }
        }
    ]
}
EOF

aws cloudwatch put-dashboard \
    --dashboard-name "BikeInventoryApp" \
    --dashboard-body file://dashboard.json \
    --region $REGION

echo "✅ Dashboard created"

echo "🎉 Monitoring setup complete!"
echo ""
echo "📋 Summary:"
echo "  Log Group: /aws/ec2/bike-inventory"
echo "  SNS Topic: $SNS_TOPIC_ARN"
echo "  Dashboard: BikeInventoryApp"
echo ""
echo "🔧 Next Steps:"
echo "1. Subscribe to SNS topic for email alerts:"
echo "   aws sns subscribe --topic-arn $SNS_TOPIC_ARN --protocol email --notification-endpoint your-email@example.com"
echo ""
echo "2. Install CloudWatch agent on EC2 instance for detailed metrics"
echo ""
echo "✨ Monitoring setup completed successfully!"

# Cleanup
rm -f dashboard.json