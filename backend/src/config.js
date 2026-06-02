import 'dotenv/config';

export const EXPIRATION_TIME_IN_SECONDS = 3600;
export const DEFAULT_AGENT_UID = 123456;

export function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function getAgentUid() {
  const raw = process.env.NEXT_PUBLIC_AGENT_UID;
  const parsed = Number.parseInt(raw ?? '', 10);
  return Number.isFinite(parsed) && parsed > 0 ? String(parsed) : String(DEFAULT_AGENT_UID);
}

export function getAgentGreeting() {
  return process.env.NEXT_AGENT_GREETING ?? "Hi there! I'm Ada, your virtual assistant from Agora. How can I help?";
}

