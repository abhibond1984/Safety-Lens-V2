import 'package:flutter/material.dart';
import '../main.dart';
import 'dashboard_tab.dart';
import 'ai_scan_tab.dart';
import 'near_miss_tab.dart';
import 'rules_tab.dart';
import 'reports_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  final _tabs = const [
    DashboardTab(),
    AIScanTab(),
    NearMissTab(),
    RulesTab(),
    ReportsTab(),
  ];

  final _navItems = const [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.camera_alt_rounded, label: 'AI Scan'),
    (icon: Icons.warning_amber_rounded, label: 'Near Miss'),
    (icon: Icons.menu_book_rounded, label: 'Rules'),
    (icon: Icons.bar_chart_rounded, label: 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_idx],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg2,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final active = _idx == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _idx = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: active ? AppColors.accent : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: active ? AppColors.accent : const Color(0xFF475569),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
