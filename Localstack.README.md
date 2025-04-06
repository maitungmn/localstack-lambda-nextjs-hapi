# Next.js with LocalStack Development Environment

This repository contains a Next.js application configured to work with LocalStack for local AWS service emulation. It includes a serverless setup with Lambda, API Gateway, and S3.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [Node.js](https://nodejs.org/) (version 20.x recommended)
- [AWS CLI](https://aws.amazon.com/cli/) (optional for local development)

## Quick Start

To run the application in production mode with LocalStack:

```bash
# Start the entire stack
./test-production.sh
```

This will:
1. Start LocalStack and the Next.js application
2. Deploy serverless resources to LocalStack
3. Configure API Gateway
4. Set up necessary AWS resources

## Environment Components

### LocalStack

LocalStack provides a local AWS cloud stack for development and testing. This setup includes:

- **Lambda**: Runs your serverless functions
- **API Gateway**: Handles API routing
- **S3**: Object storage

### Next.js Application

A Next.js application configured to work with the local AWS services.

### AWS CLI

Configured to interact with LocalStack for resource management.

## Configuration Files

### Docker Compose Files

- `docker-compose.production.yml`: Production environment configuration

```yaml
services:
  localstack:
    container_name: "${LOCALSTACK_DOCKER_NAME:-localstack-main}"
    image: localstack/localstack:latest
    ports:
      - "4566:4566"            # LocalStack Gateway
      - "4510-4559:4510-4559"  # external services port range
    environment:
      - DEBUG=${DEBUG:-1}
      - SERVICES=lambda,apigateway,s3
      - LAMBDA_EXECUTOR=docker-reuse
      - DOCKER_HOST=unix:///var/run/docker.sock
      - DATA_DIR=/var/lib/localstack/data
      - DOCKER_SDK_FROM_PATH=1
    volumes:
      - "${LOCALSTACK_VOLUME_DIR:-./volume}:/var/lib/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost.localstack.cloud:4566/_localstack/health"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 15s
    privileged: true

  nextjs-app:
    build:
      context: .
      dockerfile: Dockerfile.production
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - AWS_ENDPOINT=http://localstack:4566
      - AWS_ACCESS_KEY_ID=test
      - AWS_SECRET_ACCESS_KEY=test
      - AWS_REGION=us-east-1
    depends_on:
      localstack:
        condition: service_healthy
    restart: unless-stopped

  aws-cli:
    image: amazon/aws-cli
    environment:
      - AWS_ACCESS_KEY_ID=test
      - AWS_SECRET_ACCESS_KEY=test
      - AWS_DEFAULT_REGION=us-east-1
    volumes:
      - ./:/aws
      - ./aws-config:/root/.aws:ro
    depends_on:
      - localstack
    entrypoint: ["aws", "--endpoint-url=http://localstack:4566"]
```

### AWS CLI Configuration

To configure AWS CLI for LocalStack:

```bash
# Create directories for AWS configuration
mkdir -p aws-config

# Create config file
cat > aws-config/config << EOF
[default]
region = us-east-1
output = json

[profile tools]
region = us-east-1
output = json
EOF

# Create credentials file
cat > aws-config/credentials << EOF
[default]
aws_access_key_id = test
aws_secret_access_key = test

[tools]
aws_access_key_id = test
aws_secret_access_key = test
EOF

# Set proper permissions
chmod 600 aws-config/credentials
chmod 600 aws-config/config
```

## Accessing Services

### Next.js Application

Your Next.js application will be available at:
```
http://localhost.localstack.cloud:3000
```

### LocalStack

LocalStack services are available at:
```
http://localhost.localstack.cloud:4566
```

### API Gateway Endpoints

After deployment, your API Gateway endpoints will be available at:
```
http://localhost.localstack.cloud:4566/restapis/{API_ID}/local/_user_request_/{path}
```

To find your API ID, run:
```bash
docker-compose -f docker-compose.production.yml run --rm aws-cli apigateway get-rest-apis
```

## Common Issues and Troubleshooting

### LocalStack Docker Socket Issue

If you see an error about mounting the Docker socket:

```
Please mount the Docker socket /var/run/docker.sock as a volume when starting LocalStack
```

Make sure:
1. Docker is running
2. The Docker socket has correct permissions:
```bash
sudo chmod 666 /var/run/docker.sock
```

### AWS Profile Configuration Issues

If you encounter AWS profile errors, run the AWS configuration setup:

```bash
# Create AWS configuration
./fixed-aws-profile.sh
```

### Container Health Check Failures

If containers fail health checks:

1. Check LocalStack logs:
```bash
docker-compose -f docker-compose.production.yml logs localstack
```

2. Verify the health endpoint is accessible:
```bash
curl http://localhost.localstack.cloud:4566/_localstack/health
```

### API Gateway Issues

If you can't access API Gateway endpoints:

1. List available APIs:
```bash
docker-compose -f docker-compose.production.yml run --rm aws-cli apigateway get-rest-apis
```

2. Check API resources:
```bash
docker-compose -f docker-compose.production.yml run --rm aws-cli apigateway get-resources --rest-api-id YOUR_API_ID
```

## Cleaning Up

To stop and remove all containers:

```bash
docker-compose -f docker-compose.production.yml down -v
```

## Development Workflow

1. Make changes to your code
2. Rebuild the containers:
```bash
docker-compose -f docker-compose.production.yml build
```
3. Restart the environment:
```bash
docker-compose -f docker-compose.production.yml up -d
```
4. Re-deploy to LocalStack:
```bash
./test-production.sh
```

## Additional Resources

- [LocalStack Documentation](https://docs.localstack.cloud/overview/)
- [AWS CLI Command Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
- [Next.js Documentation](https://nextjs.org/docs)