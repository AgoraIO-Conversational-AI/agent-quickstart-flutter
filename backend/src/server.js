import { corsPreflightResponse, jsonResponse } from './http.js';
import { handleGenerateAgoraToken } from './token.js';
import { handleInviteAgent, handleStopConversation } from './agent.js';
import { requireEnv, getAgentGreeting, getAgentUid } from './config.js';
import { createServer } from 'node:http';

const port = Number.parseInt(process.env.PORT ?? '3001', 10);

async function route(request) {
  const url = new URL(request.url);
  const { pathname } = url;

  if (request.method === 'OPTIONS') {
    return corsPreflightResponse();
  }

  if (request.method === 'GET' && pathname === '/api/generate-agora-token') {
    return handleGenerateAgoraToken(request);
  }

  if (request.method === 'POST' && pathname === '/api/invite-agent') {
    return handleInviteAgent(request);
  }

  if (request.method === 'POST' && pathname === '/api/stop-conversation') {
    return handleStopConversation(request);
  }

  if (request.method === 'GET' && pathname === '/health') {
    return jsonResponse({ ok: true });
  }

  if (request.method === 'GET' && pathname === '/api/client-config') {
    return jsonResponse({
      agoraAppId: requireEnv('NEXT_PUBLIC_AGORA_APP_ID'),
      agentUid: getAgentUid(),
      agentGreeting: getAgentGreeting(),
    });
  }

  return jsonResponse({ error: 'Not found' }, 404);
}

const httpServer = createServer(async (req, res) => {
  const origin = req.headers.origin ?? 'http://localhost';
  const url = new URL(req.url ?? '/', origin);
  const chunks = [];

  for await (const chunk of req) {
    chunks.push(chunk);
  }

  const body = Buffer.concat(chunks).toString('utf8');

  const request = new Request(url, {
    method: req.method,
    headers: req.headers,
    body: body.length > 0 ? body : undefined,
  });

  try {
    const response = await route(request);
    res.writeHead(response.status, Object.fromEntries(response.headers.entries()));
    const responseBody = Buffer.from(await response.arrayBuffer());
    res.end(responseBody);
  } catch (error) {
    const response = jsonResponse(
      { error: error instanceof Error ? error.message : 'Internal server error' },
      500,
    );
    res.writeHead(response.status, Object.fromEntries(response.headers.entries()));
    const responseBody = Buffer.from(await response.arrayBuffer());
    res.end(responseBody);
  }
});

httpServer.listen(port, () => {
  console.log(`Backend companion listening on http://localhost:${port}`);
});
