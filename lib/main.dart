import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'models/conversation.dart';
import 'utils/conversation.dart';
import 'services/backend_api.dart';
import 'services/conversation_session_controller.dart';
import 'services/rtc_session_service.dart';
import 'services/rtm_session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgentQuickstartApp());
}

class AgentQuickstartApp extends StatelessWidget {
  const AgentQuickstartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'agent_quickstart_flutter',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060606),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C2FF),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF101010),
        ),
        useMaterial3: true,
      ),
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatefulWidget {
  const _BootstrapScreen();

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen> {
  late final Future<AppConfig> _configFuture;

  @override
  void initState() {
    super.initState();
    _configFuture = AppConfig.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppConfig>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load app config: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return _LandingScreen(config: snapshot.data!);
      },
    );
  }
}

class _LandingScreen extends StatefulWidget {
  const _LandingScreen({required this.config});

  final AppConfig config;

  @override
  State<_LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<_LandingScreen> {
  late final BackendApi _backendApi;
  late final ConversationSessionController _controller;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _backendApi = BackendApi(baseUrl: config.backendBaseUrl);
    _controller = ConversationSessionController(
      config: config,
      backendApi: _backendApi,
      rtcSessionService: AgoraRtcSessionService(),
      rtmSessionService: AgoraRtmSessionService(),
    )..addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _backendApi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = _controller.state;
    final hasSession = state.phase != ConversationPhase.idle;

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundGlow(),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: hasSession
                          ? _SessionCard(
                              theme: theme,
                              state: state,
                              isEnding: _controller.isEnding,
                              onEndConversation: _controller.endConversation,
                              onToggleMic: _controller.toggleMute,
                            )
                          : _PreCallCard(
                              theme: theme,
                              isStarting: _controller.isStarting,
                              error: state.errorMessage,
                              onStartConversation: _controller.startConversation,
                            ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 16,
                  bottom: 16,
                  child: _FooterMark(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF111111),
            Color(0xFF060606),
          ],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(color: Color(0xFF00C2FF), size: 220),
          ),
          Positioned(
            top: 180,
            right: -70,
            child: _GlowBlob(color: Color(0xFF1E88FF), size: 180),
          ),
          Positioned(
            bottom: -90,
            left: 80,
            child: _GlowBlob(color: Color(0xFF00A3A3), size: 240),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _PreCallCard extends StatelessWidget {
  const _PreCallCard({
    required this.theme,
    required this.isStarting,
    required this.error,
    required this.onStartConversation,
  });

  final ThemeData theme;
  final bool isStarting;
  final String? error;
  final VoidCallback onStartConversation;

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2B2B2B)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 36,
              offset: Offset(0, 12),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF232323),
              Color(0xFF0D0D0D),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Try Agora's Voice Agent",
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  height: 1.2,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Built on Agora's flagship Conversational AI engine, for effortless agentic conversations.",
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton(
                  onPressed: isStarting ? null : onStartConversation,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white,
                    disabledForegroundColor: Colors.black,
                    side: const BorderSide(color: Color(0xFF00C2FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: isStarting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text('Start Conversation'),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.theme,
    required this.state,
    required this.isEnding,
    required this.onEndConversation,
    required this.onToggleMic,
  });

  final ThemeData theme;
  final ConversationSessionState state;
  final bool isEnding;
  final VoidCallback onEndConversation;
  final VoidCallback onToggleMic;

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;
    final transcript = getMessageList(state.transcript);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2B2B2B)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 36,
              offset: Offset(0, 12),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B1B1B),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _StatusDot(
                    color: state.phase == ConversationPhase.connected
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _phaseTitle(state.phase),
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _MiniBadge(
                    text: state.isMicMuted ? 'Mic muted' : 'Mic live',
                    color: state.isMicMuted
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF22C55E),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Conversation live',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The RTC engine is joined. We are now listening for the agent voice, remote user events, and token renewals.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              _InfoPill(
                label: 'Channel',
                value: state.tokenData?.channel ?? 'n/a',
              ),
              const SizedBox(height: 8),
              _InfoPill(
                label: 'Local UID',
                value:
                    (state.localUid ?? state.tokenData?.uid ?? 'n/a').toString(),
              ),
              const SizedBox(height: 10),
              _InfoPill(
                label: 'Agent ID',
                value: state.tokenData?.agentId ?? 'pending',
              ),
              const SizedBox(height: 10),
              _InfoPill(
                label: 'Remote UID',
                value: state.remoteUid?.toString() ?? 'waiting',
              ),
              const SizedBox(height: 10),
              _InfoPill(
                label: 'State',
                value: state.connectionStatus ?? 'idle',
              ),
              if (state.agentResponse != null) ...[
                const SizedBox(height: 10),
                _InfoPill(
                  label: 'Agent',
                  value: state.agentState ?? state.agentResponse!.state,
                ),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F1D1D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7F1D1D)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.errorMessage!,
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFFCA5A5),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Event log',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 140, maxHeight: 200),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2B2B2B)),
                  ),
                  child: transcript.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Waiting for session events...',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: transcript.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = transcript[index];
                            return _TranscriptTile(item: item);
                          },
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onToggleMic,
                      icon: Icon(
                        state.isMicMuted ? Icons.mic_off : Icons.mic,
                      ),
                      label: Text(
                        state.isMicMuted ? 'Unmute mic' : 'Mute mic',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2B2B2B)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isEnding ? null : onEndConversation,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD92D20),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD92D20),
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isEnding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('End Conversation'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _phaseTitle(ConversationPhase phase) {
  return switch (phase) {
    ConversationPhase.idle => 'Idle',
    ConversationPhase.preparing => 'Preparing session',
    ConversationPhase.connecting => 'Connecting',
    ConversationPhase.connected => 'Connected',
    ConversationPhase.ending => 'Ending session',
    ConversationPhase.error => 'Session error',
  };
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _TranscriptTile extends StatelessWidget {
  const _TranscriptTile({required this.item});

  final TranscriptMessage item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSystem = item.uid == 'system';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: isSystem ? const Color(0xFF00C2FF) : Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSystem ? 'System' : 'Participant ${item.uid}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterMark extends StatelessWidget {
  const _FooterMark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Agora Conversational AI',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF6B7280),
            letterSpacing: 0.4,
          ),
    );
  }
}
