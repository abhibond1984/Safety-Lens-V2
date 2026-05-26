import 'package:flutter/material.dart';
import '../main.dart';
import '../services/local_db.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});
  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  int _total = 0;
  int _open = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await LocalDB.getIncidents();
    if (mounted) setState(() {
      _total = list.length;
      _open = list.where((i) => i['status'] == 'OPEN').length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _stat('$_total', 'Near Misses', AppColors.amber),
                  const SizedBox(width: 8),
                  _stat('87', 'Safety Score', AppColors.green),
                  const SizedBox(width: 8),
                  _stat('3', 'Inspections', AppColors.accent),
                  const SizedBox(width: 8),
                  _stat('$_open', 'Open', AppColors.red),
                ],
              ),
              const SizedBox(height: 14),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sec('WSA 13 Causes Distribution'),
                    const SizedBox(height: 12),
                    ..._wsaCauses().map(_wsaBar),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sec('Generated Reports'),
              const SizedBox(height: 10),
              _reportCard('Monthly Safety Review — May 2025', 'BSP Bhilai · All Departments · 48 pages', 'FINAL', AppColors.green),
              _reportCard('Near Miss Investigation — Local', 'Saved on device · AI Generated', 'DRAFT', AppColors.amber),
              _reportCard('PPE Compliance Audit — Q1 2025', 'All Plants · Quarterly Report', 'FINAL', AppColors.green),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  List<(String, double, Color)> _wsaCauses() => [
    ('Failure to follow procedure', 0.72, AppColors.red),
    ('Improper PPE use', 0.58, AppColors.amber),
    ('Lack of supervision', 0.45, AppColors.purple),
    ('Poor housekeeping', 0.38, AppColors.accent),
    ('Human error', 0.30, AppColors.cyan),
    ('Inadequate isolation', 0.22, AppColors.green),
  ];

  Widget _wsaBar((String, double, Color) c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(c.$1, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
              Text('${(c.$2 * 100).toInt()}%', style: TextStyle(fontSize: 11, color: c.$3, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: c.$2),
              duration: const Duration(milliseconds: 800),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: AppColors.card3,
                valueColor: AlwaysStoppedAnimation(c.$3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 8, color: AppColors.text4), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(String title, String sub, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text1))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.text4)),
          const SizedBox(height: 10),
          Row(
            children: [
              _btn('PDF', () => _toast('PDF generated offline')),
              const SizedBox(width: 6),
              _btn('Email', () => _toast('Ready to share')),
              const SizedBox(width: 6),
              _btn('CSV', () => _toast('CSV exported')),
              const SizedBox(width: 6),
              _btn('Share', () => _toast('Sharing...')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.card2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.text3)),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    );
  }

  Widget _sec(String s) => Text(s.toUpperCase(),
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text4, letterSpacing: 0.8));

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
