#!/bin/bash

# Start the production environment
echo "Starting production environment..."
docker-compose -f docker-compose.production.yml down -v
docker-compose -f docker-compose.production.yml up -d

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to be ready..."
# until docker-compose -f docker-compose.production.yml exec -T localstack curl -s http://localhost.localstack.cloud:4566/_localstack/health | grep -q '"s3":"available"'; do
#   echo "Waiting for LocalStack..."
#   sleep 5
# done
echo "LocalStack is ready!"

# Deploy to LocalStack
echo "Deploying to LocalStack..."
docker-compose -f docker-compose.production.yml run --rm aws-cli --profile=tools cloudformation deploy \
  --template-file serverless-local.yml \
  --stack-name nextjs-hapi-lambda-stack

# Get API Gateway ID
echo "Getting API Gateway ID..."
API_ID=$(docker-compose -f docker-compose.production.yml run --rm aws-cli --profile=tools \
  apigateway get-rest-apis --query "items[?name=='nextjs-hapi-lambda-local'].id" --output text)

if [ -z "$API_ID" ]; then
  echo "Failed to get API Gateway ID. Deploying Lambda function manually..."
  
  # Build the function zip
  echo "Building Lambda function..."
  zip -r function.zip dist .next public node_modules
  
  # Create Lambda function
  echo "Creating Lambda function..."
  docker-compose -f docker-compose.production.yml run --rm aws-cli --profile=tools \
    lambda create-function \
    --function-name nextjs-hapi-lambda-local-app \
    --runtime nodejs20.x \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --handler dist/server.handler \
    --zip-file fileb://function.zip

  # Create API Gateway
  echo "Creating API Gateway..."
  API_ID=$(docker-compose -f docker-compose.production.yml run --rm aws-cli --profile=tools \
    apigateway create-rest-api \
    --name nextjs-hapi-lambda-local \
    --query 'id' --output text)
fi

echo "API Gateway ID: $API_ID"
echo "Your API is available at: http://localhost.localstack.cloud:4566/restapis/$API_ID/local/_user_request_/"
echo "Test with: curl http://localhost.localstack.cloud:4566/restapis/$API_ID/local/_user_request_/api/hello"

# Test the API endpoint
echo "Testing API endpoint..."
curl -s "http://localhost.localstack.cloud:4566/restapis/$API_ID/local/_user_request_/api/hello"
echo "" # Add a newline after curl output

echo "Production testing environment is ready!"
echo "Next.js app is running at: http://localhost.localstack.cloud:3000"
echo "LocalStack Lambda endpoint is at: http://localhost.localstack.cloud:4566/restapis/$API_ID/local/_user_request_/"