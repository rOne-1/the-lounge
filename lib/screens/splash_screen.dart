import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'shell_screen.dart';

/// A splash screen displayed during app launch.
/// Reflects the app's Screening Room visual identity (champagne gold accents,
/// rich dark background `#161312`, logo icon/typography, subtle smooth fade-in animation).
class SplashScreen extends StatefulWidget {
  final bool? enableAnimation;
  final Widget? targetScreen;
  final Duration duration;

  const SplashScreen({
    super.key,
    this.enableAnimation,
    this.targetScreen,
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF161312),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    final shouldAnimate = widget.enableAnimation ?? true;

    _controller = AnimationController(
      vsync: this,
      duration: shouldAnimate ? const Duration(milliseconds: 800) : Duration.zero,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    if (shouldAnimate) {
      _controller.forward();
      _timer = Timer(widget.duration, _navigateToTarget);
    } else {
      _controller.value = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToTarget();
      });
    }
  }

  void _navigateToTarget() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final destination = widget.targetScreen ??
        ShellScreen(enableAnimation: widget.enableAnimation);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: (widget.enableAnimation ?? true)
            ? const Duration(milliseconds: 350)
            : Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF161312);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF161312),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: darkBackground,
        body: Container(
          decoration: AppThemes.screeningRoomBackground().copyWith(
            color: darkBackground,
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Screening room logo icon container with champagne gold accent glow
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.srCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.srAcc.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.srAcc.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_movies_rounded,
                      size: 42,
                      color: AppColors.srAcc,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Typography - The Lounge
                  Text(
                    'THE LOUNGE',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4.0,
                      color: AppColors.srInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle / Tagline accent
                  Text(
                    'CINEMATIC SCREENING ROOM',
                    style: AppThemes.safeGeist(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.5,
                      color: AppColors.srAcc,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
