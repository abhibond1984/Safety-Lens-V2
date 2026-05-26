import 'package:flutter/material.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [AppColors.sailBlue.withOpacity(0.25), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              ScaleTransition(
                scale: _scale,
                child: FadeTransition(
                  opacity: _fade,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset('assets/images/sail_logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              FadeTransition(
                opacity: _fade,
                child: const Text(
                  'Safety Lens',
                  style: TextStyle(
                    color: AppColors.text1,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _fade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('by ', style: TextStyle(color: AppColors.text4, fontSize: 13)),
                    Text('SAIL', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    Text(' Safety Organisation', style: TextStyle(color: AppColors.text4, fontSize: 13)),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fade,
                child: SizedBox(
                  width: 120,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.card2,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'AI-Powered Industrial Safety',
                style: TextStyle(color: Color(0xFF475569), fontSize: 11),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 5,
                children: ['BSP', 'DSP', 'RSP', 'BSL', 'ISP'].map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(p, style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    )),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
