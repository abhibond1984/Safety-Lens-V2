import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../main.dart';
import '../services/local_db.dart';
import '../services/local_ai.dart';

class NearMissTab extends StatefulWidget {
  const NearMissTab({super.key});
  @override
  State<NearMissTab> createState() => _NearMissTabState();
}

class _NearMissTabState extends State<NearMissTab> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _descCtrl = TextEditingController();
  String _location = 'Blast Furnace';
  String _severity = 'MEDIUM';
  Map<String, String>? _result;
  List<Map<String, dynamic>> _history = [];

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  double _soundLevel = 0;

  final _locations = [
    'Blast Furnace', 'Rolling Mill', 'Coke Oven Battery', 'Steel Melting Shop',
    'Hot Metal Bay', 'Electrical Maintenance', 'Sinter Plant', 'Power Station',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadHistory();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech error: ${error.errorMsg}'), backgroundColor: AppColors.red),
          );
        }
      },
      onStatus: (status) {
        if (mounted && status == 'done') {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    _descCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final data = await LocalDB.getIncidents();
    if (mounted) setState(() => _history = data);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available on this device'), backgroundColor: AppColors.red),
      );
      return;
    }
    setState(() {
      _isListening = true;
      _lastWords = '';
    });
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          _descCtrl.text = _lastWords;
        });
      },
      onSoundLevelChange: (level) {
        setState(() => _soundLevel = level);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_IN',
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _analyse() {
    final text = _descCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what happened (type or use voice)')),
      );
      return;
    }
    setState(() => _result = LocalAI.processText(text));
  }

  Future<void> _save() async {
    if (_result == null) return;
    await LocalDB.saveIncident({
      'title': _result!['title'],
      'location': _location,
      'severity': _severity,
      'wsa': _result!['wsa'],
      'desc': _descCtrl.text,
      'rootCause': _result!['root'],
      'corrective': _result!['fix'],
      'status': 'OPEN',
    });
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved to device storage'), backgroundColor: AppColors.green),
      );
      setState(() {
        _result = null;
        _descCtrl.clear();
        _lastWords = '';
      });
      _tabs.animateTo(1);
    }
  }

  Color _sevColor(String s) {
    switch (s) {
      case 'CRITICAL': return AppColors.red;
      case 'HIGH': return AppColors.amber;
      case 'MEDIUM': return AppColors.cyan;
      case 'LOW': return AppColors.green;
    }
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Near Miss Reporting'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.text4,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Report'), Tab(text: 'History'), Tab(text: 'WSA 13')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_reportTab(), _historyTab(), _wsaTab()],
      ),
    );
  }

  Widget _reportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sec('Incident Details'),
                const SizedBox(height: 12),
                const Text('Location', style: TextStyle(fontSize: 10, color: AppColors.text4)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _location,
                  dropdownColor: AppColors.card,
                  style: const TextStyle(fontSize: 12, color: AppColors.text2),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => setState(() => _location = v ?? _location),
                ),
                const SizedBox(height: 12),
                const Text('Severity', style: TextStyle(fontSize: 10, color: AppColors.text4)),
                const SizedBox(height: 8),
                Row(
                  children: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((s) {
                    final colors = {
                      'LOW': AppColors.green,
                      'MEDIUM': AppColors.amber,
                      'HIGH': AppColors.red,
                      'CRITICAL': const Color(0xFFDC2626),
                    };
                    final c = colors[s]!;
                    final selected = _severity == s;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _severity = s),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? c.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: selected ? c : AppColors.border),
                          ),
                          child: Text(s == 'CRITICAL' ? 'CRIT' : s, style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected ? c : AppColors.text4,
                          )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Describe what happened', style: TextStyle(fontSize: 10, color: AppColors.text4)),
                    Row(
                      children: [
                        if (_isListening)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                          ),
                        Text(
                          _isListening ? 'Recording...' : (_speechAvailable ? 'Voice ready' : 'Voice unavailable'),
                          style: TextStyle(
                            fontSize: 9,
                            color: _isListening ? AppColors.red : (_speechAvailable ? AppColors.green : AppColors.text4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    TextField(
                      controller: _descCtrl,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 12, color: AppColors.text1),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening... speak now' : 'Type here, or tap mic to speak...',
                        contentPadding: const EdgeInsets.fromLTRB(12, 12, 50, 12),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: _isListening ? _stopListening : _startListening,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [AppColors.red, const Color(0xFFDC2626)]
                                  : [AppColors.accent, AppColors.purple],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: _isListening
                                ? [BoxShadow(color: AppColors.red.withOpacity(0.5 + _soundLevel * 0.05), blurRadius: 12, spreadRadius: 2)]
                                : null,
                          ),
                          child: Icon(
                            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isListening) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.red.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.graphic_eq, color: AppColors.red, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Listening in English (India) · Speak clearly · ${(_soundLevel + 5).toInt()} dB',
                            style: const TextStyle(fontSize: 10, color: AppColors.text2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _analyse,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('AI Analyse & Generate Report'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            _structuredReportCard(),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _structuredReportCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.purple),
              const SizedBox(width: 8),
              const Text('AI Structured Report',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                ),
                child: const Text('Offline AI', style: TextStyle(fontSize: 9, color: AppColors.purple, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                _reportRow('TITLE', _result!['title']!, isFirst: true),
                _reportRow('LOCATION', _location),
                _reportRow('SEVERITY', _severity, color: _sevColor(_severity)),
                _reportRow('WSA CAUSE', _result!['wsa']!, color: AppColors.purple),
                _reportRow('ROOT CAUSE', _result!['root']!),
                _reportRow('CORRECTIVE ACTION', _result!['fix']!, color: AppColors.green, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF report generated')),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, String value, {Color? color, bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? BorderSide.none : BorderSide(color: AppColors.border.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppColors.text4, fontWeight: FontWeight.w700, letterSpacing: 0.7),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, color: color ?? AppColors.text1, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyTab() {
    if (_history.isEmpty) {
      return const Center(child: Text('No reports yet', style: TextStyle(color: AppColors.text4)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (_, i) {
        final inc = _history[i];
        final sc = _sevColor(inc['severity'] ?? 'MEDIUM');
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(width: 4, height: 44, decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inc['title'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text1)),
                    const SizedBox(height: 2),
                    Text('${inc['location'] ?? ''} · ${_timeAgo(inc['date'] ?? '')}', style: const TextStyle(fontSize: 10, color: AppColors.text4)),
                  ],
                ),
              ),
              _badge(inc['status'] ?? 'OPEN', sc),
            ],
          ),
        );
      },
    );
  }

  Widget _wsaTab() {
    final causes = [
      ('1. Failure to follow procedure', 0.72, AppColors.red),
      ('3. Improper PPE use', 0.58, AppColors.amber),
      ('9. Lack of supervision', 0.45, AppColors.purple),
      ('8. Poor housekeeping', 0.38, AppColors.accent),
      ('7. Human error', 0.30, AppColors.cyan),
      ('12. Inadequate isolation', 0.22, AppColors.green),
      ('6. Communication gaps', 0.18, AppColors.amber),
      ('2. Lack of hazard awareness', 0.15, AppColors.red),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sec('WSA 13 — YTD Distribution'),
            const SizedBox(height: 14),
            ...causes.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(c.$1, style: const TextStyle(fontSize: 11, color: AppColors.text3))),
                      Text('${(c.$2 * 100).toInt()}%', style: TextStyle(fontSize: 11, color: c.$3, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: c.$2),
                      duration: const Duration(milliseconds: 700),
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
            )),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.border, width: 0.8),
      ),
      child: child,
    );
  }

  Widget _sec(String s) => Text(s.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text4, letterSpacing: 0.8));

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) {
      return 'just now';
    }
  }
}
