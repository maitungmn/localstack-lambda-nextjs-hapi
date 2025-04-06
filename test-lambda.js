// test-lambda.js
import { execute } from 'lambda-local';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';


const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

execute({
  event: {
    httpMethod: 'GET',
    path: '/api/hello',
    // Add other API Gateway event properties as needed
  },
  lambdaPath: join(__dirname, 'dist/server.js'),
  lambdaHandler: 'handler',
  timeoutMs: 30000
}).then(function(result) {
  console.log('Result:', result);
}).catch(function(err) {
  console.error('Error:', err);
});

execute({
  event: {
    httpMethod: 'GET',
    path: '/',
    // Add other API Gateway event properties as needed
  },
  lambdaPath: join(__dirname, 'dist/server.js'),
  lambdaHandler: 'handler',
  timeoutMs: 30000
}).then(function(result) {
  console.log('Result:', result);
}).catch(function(err) {
  console.error('Error:', err);
});