# Google Gemini Live

This guide explains how to use Google Gemini Live with this Flutter quickstart.

The important architectural rule is simple:

- Flutter stays the client UI
- the backend companion creates and manages the agent
- the Google Gemini API key stays server-side
- the Flutter app does not call Gemini directly

## When To Use This

Use this setup when you need:

- real-time voice conversation powered by Google Gemini Live
- a Flutter app for web, Android, iOS, or macOS
- Agora-managed session control
- live transcript and agent state in the UI

Agora’s Gemini MLLM mode changes the agent pipeline. Instead of separate ASR, LLM, and TTS providers, the agent uses Gemini Live as the multimodal model.

## What Changes In This Repo

The Flutter UI mostly stays the same.

What changes is the backend agent configuration:

- remove the separate ASR / LLM / TTS chain
- enable `mllm`
- set the vendor to `gemini`
- pass the Google Gemini API key in backend configuration
- keep RTM enabled if transcript and agent-state updates are needed in the UI

## Full Implementation Path

This shows exactly what to change, where to change it, and why.

### Step 1. Add Gemini env vars

File:

- repo-root `.env.local`

Add the Gemini key and optional model overrides:

```dotenv
NEXT_PUBLIC_AGORA_APP_ID=your_agora_app_id
NEXT_AGORA_APP_CERTIFICATE=your_agora_app_certificate
GOOGLE_GEMINI_API_KEY=your_google_gemini_api_key
GEMINI_MLLM_MODEL=gemini-3.1-flash-live-preview
GEMINI_MLLM_VOICE=Charon
NEXT_PUBLIC_AGENT_UID=123456
NEXT_AGENT_GREETING=Hi, how can I help?
```

Why:

- the backend needs the Google key to create the agent
- the model and voice should stay configurable for project-specific deployments
- the client should never see the Google API key

### Step 2. Add backend config helpers

File:

- [`backend/src/config.js`](../../backend/src/config.js)

Add explicit Gemini helpers so the rest of the backend does not need to know environment details:

```js
export function getGeminiApiKey() {
  return requireEnv('GOOGLE_GEMINI_API_KEY');
}

export function getGeminiModel() {
  return process.env.GEMINI_MLLM_MODEL ?? 'gemini-3.1-flash-live-preview';
}

export function getGeminiVoice() {
  return process.env.GEMINI_MLLM_VOICE ?? 'Charon';
}
```

Why:

- it keeps secret lookup and defaults in one place
- it makes the agent file much easier to read and maintain
- it gives developers a single place to change Gemini defaults later

### Step 3. Replace the cascading provider chain with `GeminiLive`

File:

- [`backend/src/agent.js`](../../backend/src/agent.js)

Replace the separate STT/LLM/TTS imports:

```js
import {
  AgoraClient,
  Agent,
  Area,
  ExpiresIn,
  GeminiLive,
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
  new GeminiLive({
    apiKey: getGeminiApiKey(),
    model: getGeminiModel(),
    instructions: ADA_PROMPT,
    voice: getGeminiVoice(),
    greetingMessage: getAgentGreeting(),
    failureMessage: 'Please wait a moment.',
    inputModalities: ['audio'],
    outputModalities: ['audio'],
    additionalParams: {
      http_options: {
        api_version: 'v1beta',
      },
    },
    turnDetection: {
      mode: 'agora_vad',
      agora_vad_config: {
        interrupt_duration_ms: 160,
        prefix_padding_ms: 300,
        silence_duration_ms: 480,
        threshold: 0.5,
      },
    },
  }),
);
```

Why:

- Agora’s MLLM mode handles the real-time audio loop directly
- `withMllm()` automatically enables MLLM and replaces the cascading ASR + LLM + TTS pipeline
- the SDK’s GeminiLive vendor maps directly to Agora’s Gemini MLLM configuration

Important implementation note:

- do not mix `withMllm()` with `withStt()`, `withLlm()`, or `withTts()` on the same agent
- the Agora package explicitly treats MLLM as a replacement for the cascading pipeline

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

- `invite-agent` now creates a Gemini Live MLLM agent
- `stop-conversation` still shuts the agent down cleanly
- `client-config` can stay as-is unless you want to expose a visible Gemini label or model string to the UI

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
- a Google Gemini API key from Google AI Studio

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

Update the docs so they match the Gemini path:

- say the backend companion is still required
- say Gemini Live replaces separate ASR, LLM, and TTS vendors
- say the Google API key stays server-side
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

After making the Gemini change, check:

```bash
flutter analyze
flutter test
cd backend && node --check src/*.js
```

Then run the app and verify:

- the backend starts without errors
- the invite route creates a Gemini Live agent
- the Flutter UI joins RTC successfully
- transcript appears in the UI
- agent state updates appear in the UI
- the stop flow shuts the session down cleanly

## Recommended Developer Flow

If a developer wants the cleanest implementation path, do it in this order:

1. Add the Gemini env vars to `.env.local`.
2. Add the config helpers in `backend/src/config.js`.
3. Replace the backend provider chain with `GeminiLive` in `backend/src/agent.js`.
4. Keep the existing backend routes and token flow.
5. Verify the Flutter transcript parser still understands the runtime payloads.
6. Update the README and docs to match the Gemini mode.
7. Run the validation commands.

That sequence keeps the repo stable while moving from the current STT + LLM + TTS setup to Gemini Live.
