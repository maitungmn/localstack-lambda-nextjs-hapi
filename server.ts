import Hapi from '@hapi/hapi';
import next from 'next';
import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import serverless, { Application } from 'serverless-http';

const dev = process.env.NODE_ENV !== 'production';
const app = next({ dev });
const handle = app.getRequestHandler();

// Initialize the Hapi server
const server = Hapi.server({
  port: process.env.PORT || 3000,
  host: '0.0.0.0',
});

// Add routes to the Hapi server
async function init() {
  await app.prepare();
  
  // API routes
  server.route({
    method: '*',
    path: '/api/{any*}',
    handler: async (request, h) => {
      // Example API endpoint
      if (request.path === '/api/hello') {
        return { message: 'Hello from Hapi.js!' };
      }
      // Add more API routes as needed
      
      // If no API route matches, return 404
      return h.response({ error: 'Not Found' }).code(404);
    },
  });
  
  // Next.js pages route - handle all other routes with Next.js
  server.route({
    method: '*',
    path: '/{any*}',
    handler: async (request, h) => {
      try {
        // Get raw request and raw response objects
        const { raw: { req, res } } = request;
        
        // Let Next.js handle the rendering
        await handle(req, res);
        
        // Return a response to prevent Hapi from overriding Next.js response
        return h.abandon;
      } catch (error) {
        console.error('Error handling Next.js request:', error);
        return h.response('Internal Server Error').code(500);
      }
    },
  });

  // Initialize the server if running standalone (not as Lambda)
  if (!process.env.AWS_LAMBDA_FUNCTION_NAME) {
    await server.start();
    console.log('Server running on %s', server.info.uri);
  }
  
  return server;
}

// Initialize the server
let cachedServer: Hapi.Server | null = null;

async function getServer() {
  if (!cachedServer) {
    cachedServer = await init();
  }
  return cachedServer;
}

// Lambda handler
export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  const server = await getServer();
  const handler = serverless(server as Application);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return handler(event, context) as any;
};

// For local development
if (!process.env.AWS_LAMBDA_FUNCTION_NAME) {
  init();
}