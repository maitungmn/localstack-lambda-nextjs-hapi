#!/bin/bash

# Create AWS CLI configuration directory
echo "Creating AWS CLI configuration..."
mkdir -p aws-config

# Create AWS config file
cat > aws-config/config << EOF
[default]
region = us-east-1
output = json

[profile tools]
region = us-east-1
output = json
EOF

# Create AWS credentials file
cat > aws-config/credentials << EOF
[default]
aws_access_key_id = test
aws_secret_access_key = test

[tools]
aws_access_key_id = test
aws_secret_access_key = test
EOF

# Set the proper permissions
chmod 600 aws-config/credentials
chmod 600 aws-config/config

echo "AWS configuration created successfully."
echo ""
echo "Testing AWS CLI configuration..."

# Test AWS CLI configuration with docker-compose
docker-compose -f docker-compose.production.yml run --rm \
  -v $PWD/aws-config:/root/.aws aws-cli \
  --profile tools \
  --endpoint-url=http://localhost.localstack.cloud:4566 \
  s3api list-buckets

echo ""
echo "=== AWS CLI Configuration Status ==="
docker-compose -f docker-compose.production.yml run --rm \
  -v $PWD/aws-config:/root/.aws aws-cli \
  --endpoint-url=http://localhost.localstack.cloud:4566 \
  configure list

echo ""
echo "=== Available Profiles ==="
docker-compose -f docker-compose.production.yml run --rm \
  -v $PWD/aws-config:/root/.aws aws-cli \
  configure list-profiles