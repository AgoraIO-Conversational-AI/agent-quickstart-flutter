import 'package:flutter/material.dart';

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

class _LandingScreen extends StatelessWidget {
  const _LandingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      child: _PreCallCard(theme: theme),
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
  const _PreCallCard({required this.theme});

  final ThemeData theme;

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
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Color(0xFF00C2FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Start Conversation'),
                ),
              ),
            ],
          ),
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
