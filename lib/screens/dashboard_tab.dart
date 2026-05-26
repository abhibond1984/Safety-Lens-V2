import 'package:flutter/material.dart';
import '../main.dart';
import '../services/local_db.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _nearMissCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await LocalDB.getIncidents();
    if (mounted) setState(() => _nearMissCount = list.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/images/sail_logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Safety Lens', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text('by SAIL Safety Organisation', style: TextStyle(fontSize: 9, color: AppColors.text4)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('3 new alerts')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 22),
            onPressed: () => _showProfile(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good morning, R.K. Sharma', style: TextStyle(color: AppColors.text3, fontSize: 13)),
              const SizedBox(height: 4),
              const Text(
                'Safety Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1),
              ),
              const SizedBox(height: 16),
              _scoreCard(),
              const SizedBox(height: 12),
              _kpiGrid(),
              const SizedBox(height: 16),
              const _SectionHeader('AI Safety Alerts'),
              const SizedBox(height: 8),
              _alertCard(AppColors.red, 'Critical: No hard hat at BF-5', 'Offline AI · WSA #3', '2m'),
              _alertCard(AppColors.amber, 'Crane near miss · Rolling Mill', 'Under investigation', '4d'),
              _alertCard(AppColors.green, 'Housekeeping score improved', 'Coke Oven Battery 4 · +12%', '1h'),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent.withOpacity(0.12), AppColors.purple.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: 0.87,
                    strokeWidth: 7,
                    backgroundColor: AppColors.card3,
                    valueColor: AlwaysStoppedAnimation(AppColors.green),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('87', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.green)),
                    Text('SCORE', style: TextStyle(fontSize: 8, color: AppColors.text4, letterSpacing: 1.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Good Standing',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.green)),
                    const SizedBox(width: 8),
                    _badge('↑ 3.2%', AppColors.green),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('BSP Bhilai · Blast Furnace', style: TextStyle(fontSize: 11, color: AppColors.text3)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _badge('Rank #4/12', AppColors.accent),
                    const SizedBox(width: 6),
                    _badge('May 2025', AppColors.text4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _kpi('$_nearMissCount', 'Near Misses', '▲ local data', AppColors.amber, Icons.warning_amber_rounded),
        _kpi('94%', 'PPE Compliance', '↑ offline tracked', AppColors.green, Icons.security_rounded),
        _kpi('3', 'Inspections', '↑ done today', AppColors.accent, Icons.fact_check_rounded),
        _kpi('2', 'Open Critical', 'Needs attention', AppColors.red, Icons.error_outline_rounded),
      ],
    );
  }

  Widget _kpi(String val, String label, String trend, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text4, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(trend, style: TextStyle(fontSize: 9, color: color)),
        ],
      ),
    );
  }

  Widget _alertCard(Color dot, String title, String sub, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text1)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _showProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accent,
                    child: Text('R', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('R.K. Sharma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Text('Sr. Safety Officer · BSP', style: TextStyle(fontSize: 11, color: AppColors.text3)),
                      const SizedBox(height: 4),
                      _badge('Admin', AppColors.purple),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: AppColors.green, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Offline · No internet, no API keys, no cloud',
                        style: TextStyle(fontSize: 11, color: AppColors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.red, size: 16),
                  label: const Text('Sign Out', style: TextStyle(color: AppColors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.text4,
        letterSpacing: 0.8,
      ),
    );
  }
}
