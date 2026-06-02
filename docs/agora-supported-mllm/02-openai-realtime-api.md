# OpenAI Realtime API

This guide explains how to use Agora-supported OpenAI Realtime MLLM with this Flutter quickstart.

The architecture is the same as the Gemini guide:

- Flutter stays the client UI
- the backend companion creates and manages the agent
- the OpenAI API key stays server-side
- the Flutter app does not call OpenAI directly

## When To Use This

Use this setup when you need:

- real-time voice conversation powered by OpenAI Realtime API
- a Flutter app for web, Android, iOS, or macOS
- Agora-managed session control
- live transcript and agent state in the UI

Agora’s OpenAI Realtime MLLM mode changes the agent pipeline. Instead of separate ASR, LLM, and TTS providers, the agent uses OpenAI Realtime as the multimodal model.

## What Changes In This Repo

The Flutter UI mostly stays the same.

What changes is the backend agent configuration:

- remove the separate ASR / LLM / TTS chain
- enable `mllm`
- set the vendor to `openai`
- pass the OpenAI API key in backend configuration
- keep RTM enabled if transcript and agent-state updates are needed in the UI

## Full Implementation Path

This shows exactly what to change, where to change it, and why.

### Step 1. Add OpenAI env vars

File:

- repo-root `.env.local`

Add the OpenAI key and optional model overrides:

```dotenv
NEXT_PUBLIC_AGORA_APP_ID=your_agora_app_id
NEXT_AGORA_APP_CERTIFICATE=your_agora_app_certificate
OPENAI_REALTIME_API_KEY=your_openai_api_key
OPENAI_REALTIME_MODEL=gpt-realtime
OPENAI_REALTIME_VOICE=coral
OPENAI_REALTIME_LANGUAGE=en
NEXT_PUBLIC_AGENT_UID=123456
NEXT_AGENT_GREETING=Hello, how can I help?
```

Why:

- the backend needs the OpenAI key to create the agent
- the model, voice, and transcription language should be configurable
- the client should never see the OpenAI API key

### Step 2. Add backend config helpers

File:

- [`backend/src/config.js`](../../backend/src/config.js)

Add explicit OpenAI helpers so the backend logic stays readable:

```js
export function getOpenAIRealtimeApiKey() {
  return requireEnv('OPENAI_REALTIME_API_KEY');
}

export function getOpenAIRealtimeModel() {
  return process.env.OPENAI_REALTIME_MODEL ?? 'gpt-realtime';
}

export function getOpenAIRealtimeVoice() {
  return process.env.OPENAI_REALTIME_VOICE ?? 'coral';
}

export function getOpenAIRealtimeLanguage() {
  return process.env.OPENAI_REALTIME_LANGUAGE ?? 'en';
}
```

Why:

- it centralizes secret lookup and defaults
- it gives developers a single place to tune realtime voice settings
- it keeps the agent file focused on the session logic

### Step 3. Replace the cascading provider chain with `OpenAIRealtime`

File:

- [`backend/src/agent.js`](../../backend/src/agent.js)

Replace the separate STT/LLM/TTS imports:

```js
import {
  AgoraClient,
  Agent,
  Area,
  ExpiresIn,
  OpenAIRealtime,
} from 'agora-agents';
```

Then replace the current `.withStt(...).withLlm(...).withTts(...)` chain with a single MLLM builder:

```js
const agent = new Agent({
  name: `conversation-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`,
  advancedFeatures: {
    enable_rtm: true,
    enable_tools: true,
  },
  parameters: {
    data_channel: 'rtm',
    enable_error_message: true,
    enable_metrics: true,
  },
}).withMllm(
  new OpenAIRealtime({
    apiKey: getOpenAIRealtimeApiKey(),
    model: getOpenAIRealtimeModel(),
    url: 'wss://api.openai.com/v1/realtime',
    greetingMessage: getAgentGreeting(),
    failureMessage: 'Please wait a moment.',
    outputModalities: ['text', 'audio'],
    params: {
      voice: getOpenAIRealtimeVoice(),
      instructions: ADA_PROMPT,
      input_audio_transcription: {
        language: getOpenAIRealtimeLanguage(),
        model: 'gpt-4o-mini-transcribe',
        prompt: 'expect words related to real-time engagement',
      },
    },
    turnDetection: {
      mode: 'server_vad',
      server_vad_config: {
        prefix_padding_ms: 800,
        silence_duration_ms: 640,
        threshold: 0.5,
      },
    },
  }),
);
```

Why:

- Agora’s MLLM mode handles the real-time audio loop directly
- `withMllm()` automatically enables MLLM and replaces the cascading ASR + LLM + TTS pipeline
- OpenAI Realtime expects a WebSocket URL plus the OpenAI API key and realtime params

Important implementation note:

- do not mix `withMllm()` with `withStt()`, `withLlm()`, or `withTts()` on the same agent
- the Agora SDK treats MLLM as a replacement for the cascading pipeline

### Step 4. Keep the agent lifecycle flow the same

File:

- [`backend/src/server.js`](../../backend/src/server.js)

You usually do not need to change the routing layer.

Keep the same endpoints:

```js
GET /api/generate-agora-token
POST /api/invite-agent
POST /api/stop-conversation
GET /api/client-config
```

Why:

- the Flutter app still needs token generation and agent start/stop
- the backend route structure already matches the repo contract

What changes behind the route:

- `invite-agent` now creates an OpenAI Realtime MLLM agent
- `stop-conversation` still shuts the agent down cleanly
- `client-config` can stay as-is unless you want to expose a visible OpenAI label or model string to the UI

## Files You Will Usually Edit

- [`backend/src/agent.js`](../../backend/src/agent.js)
- [`backend/src/config.js`](../../backend/src/config.js)
- [`backend/src/server.js`](../../backend/src/server.js)
- [`README.md`](../../README.md)
- [`docs/ai/L1/06_interfaces.md`](../ai/L1/06_interfaces.md)

## Prerequisites

Before changing code, make sure you have:

- an Agora project with Conversational AI enabled
- an Agora App ID
- an Agora App Certificate
- an OpenAI API key

## Remaining Steps

### 5. Keep RTM if the UI needs transcript and state

If you want live transcript or agent-state updates in the Flutter UI, keep RTM enabled.

Why:

- RTM is still how this repo receives transcript/state payloads
- the Flutter parser and UI already expect RTM-driven events

What to verify:

- transcript payload shape
- agent-state payload shape
- token privileges include RTM when required

### 6. Update the Flutter UI only if payloads change

The Flutter side usually does not need a rewrite.

You only need to change Flutter code if:

- transcript events change shape
- agent-state events change shape
- the UI needs different labels or status text

Useful files:

- [`lib/services/conversation_session_controller.dart`](../../lib/services/conversation_session_controller.dart)
- [`lib/utils/rtm_transcript_parser.dart`](../../lib/utils/rtm_transcript_parser.dart)
- [`lib/services/backend_api.dart`](../../lib/services/backend_api.dart)

### 7. Keep the docs in sync

Files:

- [`README.md`](../../README.md)
- [`docs/ai/L1/06_interfaces.md`](../ai/L1/06_interfaces.md)
- [`docs/agora-supported-mllm/README.md`](./README.md)

Update the docs so they match the OpenAI Realtime path:

- say the backend companion is still required
- say OpenAI Realtime replaces separate ASR, LLM, and TTS vendors
- say the OpenAI API key stays server-side
- show the new env vars

Why:

- the developer experience should match the actual implementation
- the docs should answer the “what do I change?” question without requiring source-code archeology

## Why This Split Exists

This repo uses a client + backend companion design because:

- the App Certificate must stay server-side
- agent lifecycle calls are privileged
- the same backend can support web, Android, iOS, and macOS
- it keeps the Flutter app focused on UI and device behavior

## Validation Checklist

After making the OpenAI Realtime change, check:

```bash
flutter analyze
flutter test
cd backend && node --check src/*.js
```

Then run the app and verify:

- the backend starts without errors
- the invite route creates an OpenAI Realtime agent
- the Flutter UI joins RTC successfully
- transcript appears in the UI
- agent state updates appear in the UI
- the stop flow shuts the session down cleanly

## Recommended Developer Flow

If a developer wants the cleanest implementation path, do it in this order:

1. Add the OpenAI env vars to `.env.local`.
2. Add the config helpers in `backend/src/config.js`.
3. Replace the backend provider chain with `OpenAIRealtime` in `backend/src/agent.js`.
4. Keep the existing backend routes and token flow.
5. Verify the Flutter transcript parser still understands the runtime payloads.
6. Update the README and docs to match the OpenAI Realtime mode.
7. Run the validation commands.

That sequence keeps the repo stable while moving from the current STT + LLM + TTS setup to OpenAI Realtime.
