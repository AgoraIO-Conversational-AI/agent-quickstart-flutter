import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'models/conversation.dart';
import 'services/backend_api.dart';

void main() {
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
      home: const _LandingScreen(),
    );
  }
}

class _LandingScreen extends StatefulWidget {
  const _LandingScreen();

  @override
  State<_LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<_LandingScreen> {
  late final AppConfig _config;
  late final BackendApi _backendApi;

  AgoraTokenData? _sessionData;
  AgentResponse? _agentResponse;
  String? _error;
  bool _isStarting = false;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _config = AppConfig.fromEnvironment();
    _backendApi = BackendApi(baseUrl: _config.backendBaseUrl);
  }

  @override
  void dispose() {
    _backendApi.dispose();
    super.dispose();
  }

  Future<void> _startConversation() async {
    if (_isStarting || _sessionData != null) return;

    setState(() {
      _isStarting = true;
      _error = null;
    });

    try {
      final tokenData = await _backendApi.generateToken(
        uid: _config.agentUid.toString(),
      );
      final agentResponse = await _backendApi.inviteAgent(
        ClientStartRequest(
          requesterId: tokenData.uid,
          channelName: tokenData.channel,
        ),
      );

      if (!mounted) return;
      setState(() {
        _sessionData = tokenData.copyWithAgent(agentResponse.agentId);
        _agentResponse = agentResponse;
      });
    } on BackendApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _endConversation() async {
    if (_isEnding) return;

    final agentId = _sessionData?.agentId;
    if (agentId == null || agentId.isEmpty) {
      setState(() {
        _sessionData = null;
        _agentResponse = null;
      });
      return;
    }

    setState(() {
      _isEnding = true;
      _error = null;
    });

    try {
      await _backendApi.stopConversation(
        StopConversationRequest(agentId: agentId),
      );
    } on BackendApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _sessionData = null;
          _agentResponse = null;
          _isEnding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSession = _sessionData != null;

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
                              sessionData: _sessionData!,
                              agentResponse: _agentResponse,
                              isEnding: _isEnding,
                              onEndConversation: _endConversation,
                            )
                          : _PreCallCard(
                              theme: theme,
                              isStarting: _isStarting,
                              error: _error,
                              onStartConversation: _startConversation,
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
    required this.sessionData,
    required this.agentResponse,
    required this.isEnding,
    required this.onEndConversation,
  });

  final ThemeData theme;
  final AgoraTokenData sessionData;
  final AgentResponse? agentResponse;
  final bool isEnding;
  final VoidCallback onEndConversation;

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;

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
              Color(0xFF1F1F1F),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Conversation ready',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'The backend returned a valid token and agent invite response. Next we wire RTC, RTM, and transcript events into this session shell.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              _InfoPill(label: 'Channel', value: sessionData.channel),
              const SizedBox(height: 10),
              _InfoPill(label: 'User UID', value: sessionData.uid),
              const SizedBox(height: 10),
              _InfoPill(label: 'Agent ID', value: sessionData.agentId ?? 'n/a'),
              if (agentResponse != null) ...[
                const SizedBox(height: 10),
                _InfoPill(label: 'State', value: agentResponse!.state),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: isEnding ? null : onEndConversation,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD92D20),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD92D20),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: isEnding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('End Conversation'),
                ),
              ),
            ],
          ),
        ),
      ),
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

extension on AgoraTokenData {
  AgoraTokenData copyWithAgent(String? agentId) {
    return AgoraTokenData(
      token: token,
      uid: uid,
      channel: channel,
      agentId: agentId ?? this.agentId,
    );
  }
}
