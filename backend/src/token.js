import agoraToken from 'agora-token';
import { EXPIRATION_TIME_IN_SECONDS, requireEnv } from './config.js';
import { generateChannelName, jsonResponse, parseUid } from './http.js';

const { RtcRole, RtcTokenBuilder } = agoraToken;

export async function handleGenerateAgoraToken(request) {
  try {
    const appId = requireEnv('NEXT_PUBLIC_AGORA_APP_ID');
    const appCertificate = requireEnv('NEXT_AGORA_APP_CERTIFICATE');

    const url = new URL(request.url);
    const uid = parseUid(url.searchParams.get('uid'));
    const channelName = url.searchParams.get('channel') || generateChannelName();
    const expirationTime = Math.floor(Date.now() / 1000) + EXPIRATION_TIME_IN_SECONDS;

    const token = RtcTokenBuilder.buildTokenWithRtm(
      appId,
      appCertificate,
      channelName,
      uid.toString(),
      RtcRole.PUBLISHER,
      expirationTime,
      expirationTime,
    );

    return jsonResponse({
      token,
      uid: uid.toString(),
      channel: channelName,
    });
  } catch (error) {
    return jsonResponse(
      {
        error: 'Failed to generate Agora token',
        details: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
}
