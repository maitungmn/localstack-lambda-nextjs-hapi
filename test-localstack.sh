#!/bin/bash

# Use AWS CLI with endpoint URL instead of awslocal
AWS_LOCAL="aws --endpoint-url=http://localhost.localstack.cloud:4566"

# Build the app
echo "Building the Next.js application..."
npm run build

# Deploy to LocalStack
echo "Deploying to LocalStack..."
serverless deploy --config serverless-local.yml --stage local

# Wait a moment for deployment to complete
sleep 5

# Extract the API ID from the deployment output
echo "Getting API Gateway ID..."
API_ID=$($AWS_LOCAL apigateway get-rest-apis --query "items[?name=='nextjs-hapi-lambda-local'].id" --output text)

if [ -z "$API_ID" ]
then
  echo "Failed to get API Gateway ID. Make sure LocalStack is running and the deployment was successful."
  exit 1
fi

echo "API Gateway ID: $API_ID"
echo "Your API is available at: http://localhost.localstack.cloud:4566/restapis/$API_ID/local/_user_request_/"
echo "Test with: curl http://localhost.localstack.cloud:4566/restapis/$API_ID/local/_user_request_/api/hello"

# Test API endpoint
echo "Testing API endpoint..."
curl -s "http://localhost.localstack.cloud:4566/restapis/$API_ID/local/_user_request_/api/hello"
echo "" # Add a newline after curl output

# List deployed Lambda functions
echo "Deployed Lambda functions:"
$AWS_LOCAL lambda list-functions --query "Functions[].FunctionName" --output table

# Optional: Open in browser
if command -v open &> /dev/null; then
    echo "Opening in browser..."
    open "http://localhost.localstack.cloud:4566/restapis/$API_ID/local/_user_request_/"
elif command -v xdg-open &> /dev/null; then
    echo "Opening in browser..."
    xdg-open "http://localhost.localstack.cloud:4566/restapis/$API_ID/local/_user_request_/"
fi

echo "LocalStack testing setup complete!"