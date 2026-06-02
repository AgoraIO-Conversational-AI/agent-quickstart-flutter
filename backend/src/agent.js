import {
  AgoraClient,
  Agent,
  Area,
  DeepgramSTT,
  ExpiresIn,
  MiniMaxTTS,
  OpenAI,
} from 'agora-agents';
import { DEFAULT_AGENT_UID, getAgentGreeting, requireEnv } from './config.js';
import { jsonResponse, readJsonBody } from './http.js';

const ADA_PROMPT = `You are **Ada**, an agentic developer advocate from **Agora**. You help developers understand and build with Agora's Conversational AI platform.

# What Agora Actually Is
Agora is a real-time communications company. The product you represent is the **Agora Conversational AI Engine** — it lets developers add voice AI agents to any app by connecting ASR, LLM, and TTS into a real-time pipeline over Agora's SD-RTN (Software Defined Real-Time Network). Key facts:
- The product is called the **Conversational AI Engine** (not "Chorus", not "Harmony", or any other name you might invent)
- It runs a full ASR → LLM → TTS pipeline with sub-500ms latency
- It supports Deepgram, Microsoft, and others for ASR; OpenAI, Anthropic, and others for LLM; ElevenLabs, Microsoft, and others for TTS
- Agora's SD-RTN is its global real-time network infrastructure — not "SDRTN"
- MCP in this context means **Model Context Protocol** (Anthropic's open standard for connecting AI models to tools/data), not "multi-channel processing"
- Agora does not have a product called Chorus, Harmony, or any similar name — do not invent product names

# Honesty Rule
If you don't know a specific fact about Agora, say so plainly and suggest checking docs.agora.io. Never invent product names, feature names, or capabilities.

# Persona & Tone
- Friendly, technically credible, concise. You're a peer who builds things, not a support agent.
- Plain English. No marketing fluff.

# Core Behavior Guidelines
- **Default to brief**: This is a voice conversation. Keep most replies to 1–2 sentences. Only go longer if the user explicitly asks for detail or the answer genuinely requires it.
- **Never list or enumerate**: No bullet points, no numbered steps. Say the single most important thing.
- **Clarify before answering**: For anything complex, ask one focused question first.
- **Ask at most one question per turn**: Never stack questions.
- **Guide, don't lecture**: Unlock the next step, not everything at once.`;

function isAgentAlreadyStoppingOrStopped(error) {
  if (!error || typeof error !== 'object') return false;
  const maybeErr = error;
  const statusCode = maybeErr.statusCode;
  const reason = maybeErr.body?.reason?.toLowerCase();
  const detail = maybeErr.body?.detail?.toLowerCase() ?? maybeErr.message?.toLowerCase() ?? '';
  if (statusCode === 404) return true;
  if (reason === 'invalidrequest' && detail.includes('already in the process of shutting down')) {
    return true;
  }
  return false;
}

export async function handleInviteAgent(request) {
  try {
    const body = await readJsonBody(request);
    const { requester_id, channel_name } = body;

    if (!requester_id || !channel_name) {
      return jsonResponse({ error: 'channel_name and requester_id are required' }, 400);
    }

    const appId = requireEnv('NEXT_PUBLIC_AGORA_APP_ID');
    const appCertificate = requireEnv('NEXT_AGORA_APP_CERTIFICATE');

    const client = new AgoraClient({
      area: Area.US,
      appId,
      appCertificate,
    });

    const agent = new Agent({
      name: `conversation-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`,
      instructions: ADA_PROMPT,
      greeting: getAgentGreeting(),
      failureMessage: 'Please wait a moment.',
      maxHistory: 50,
      turnDetection: {
        config: {
          speech_threshold: 0.5,
          start_of_speech: {
            mode: 'vad',
            vad_config: {
              interrupt_duration_ms: 160,
              prefix_padding_ms: 300,
            },
          },
          end_of_speech: {
            mode: 'vad',
            vad_config: {
              silence_duration_ms: 480,
            },
          },
        },
      },
      advancedFeatures: { enable_rtm: true, enable_tools: true },
      parameters: {
        data_channel: 'rtm',
        enable_error_message: true,
        enable_metrics: true,
      },
    })
      .withStt(
        new DeepgramSTT({
          model: 'nova-3',
          language: 'en',
        }),
      )
      .withLlm(
        new OpenAI({
          model: 'gpt-4o-mini',
          greetingMessage: getAgentGreeting(),
          failureMessage: 'Please wait a moment.',
          maxHistory: 15,
          params: {
            max_tokens: 1024,
            temperature: 0.7,
            top_p: 0.95,
          },
        }),
      )
      .withTts(
        new MiniMaxTTS({
          model: 'speech_2_6_turbo',
          voiceId: 'English_captivating_female1',
        }),
      );

    const session = agent.createSession(client, {
      channel: channel_name,
      agentUid: process.env.NEXT_PUBLIC_AGENT_UID ?? String(DEFAULT_AGENT_UID),
      remoteUids: [requester_id],
      idleTimeout: 30,
      expiresIn: ExpiresIn.hours(1),
      debug: false,
    });

    const agentId = await session.start();

    return jsonResponse({
      agent_id: agentId,
      create_ts: Math.floor(Date.now() / 1000),
      state: 'RUNNING',
    });
  } catch (error) {
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : 'Failed to start conversation',
      },
      500,
    );
  }
}

export async function handleStopConversation(request) {
  try {
    const body = await readJsonBody(request);
    const { agent_id } = body;

    if (!agent_id) {
      return jsonResponse({ error: 'agent_id is required' }, 400);
    }

    const appId = requireEnv('NEXT_PUBLIC_AGORA_APP_ID');
    const appCertificate = requireEnv('NEXT_AGORA_APP_CERTIFICATE');

    const client = new AgoraClient({
      area: Area.US,
      appId,
      appCertificate,
    });

    try {
      await client.stopAgent(agent_id);
    } catch (error) {
      if (isAgentAlreadyStoppingOrStopped(error)) {
        return jsonResponse({ success: true, state: 'already-stopping' });
      }
      throw error;
    }

    return jsonResponse({ success: true });
  } catch (error) {
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : 'Failed to stop conversation',
      },
      500,
    );
  }
}

