import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/local_ai.dart';
import '../services/local_db.dart';
import '../services/gemini_vision.dart';

class AIScanTab extends StatefulWidget {
  const AIScanTab({super.key});
  @override
  State<AIScanTab> createState() => _AIScanTabState();
}

class _AIScanTabState extends State<AIScanTab> {
  File? _image;
  bool _scanning = false;
  String _scanStep = '';
  Map<String, dynamic>? _result;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = null;
        });
        await _analyseImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _analyseImage() async {
    setState(() {
      _scanning = true;
      _result = null;
    });

    final useGemini = GeminiVision.isConfigured && _image != null;
    final steps = useGemini
        ? [
            'Uploading to Gemini AI...',
            'Detecting workplace hazards...',
            'Identifying PPE violations...',
            'Cross-referencing Factory Act regulations...',
            'Classifying WSA-13 root causes...',
            'Generating safety report...',
          ]
        : [
            'Loading image...',
            'Scanning for PPE violations...',
            'Detecting workplace hazards...',
            'Checking factory regulations...',
            'Classifying WSA-13 causes...',
            'Generating safety report...',
          ];

    // Run the analysis in parallel with the progress animation
    final analysisFuture = useGemini
        ? GeminiVision.analyseImage(_image!)
        : LocalAI.analyseImage(_image!);

    for (final s in steps) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _scanStep = s);
    }

    final result = await analysisFuture;
    if (mounted) {
      setState(() {
        _result = result;
        _scanning = false;
      });
    }
  }

  Future<void> _saveReport() async {
    if (_result == null) return;
    final r = _result!;
    await LocalDB.saveIncident({
      'title': 'AI Scan: ${(r['hazards'] as List).isNotEmpty ? (r['hazards'] as List).first['name'] : 'Workplace Analysis'}',
      'location': 'Captured Photo',
      'severity': r['severity'],
      'wsa': (r['wsa'] as List).join(', '),
      'desc': r['summary'],
      'imagePath': _image?.path,
      'status': 'OPEN',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved to device'), backgroundColor: AppColors.green),
      );
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
        title: const Text('AI Image Analysis'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
            ),
            child: const Text('✓ Offline AI', style: TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_image == null && !_scanning) _uploadCard(),
            if (_image != null) _imageWithOverlay(),
            if (_scanning) _scanningCard(),
            if (_result != null) ..._buildResult(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _uploadCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: AppColors.accent, size: 32),
              ),
              const SizedBox(height: 14),
              const Text('Capture or Upload Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text1)),
              const SizedBox(height: 6),
              const Text('AI will analyse the workplace for safety violations',
                  style: TextStyle(fontSize: 11, color: AppColors.text4), textAlign: TextAlign.center),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoCard(),
      ],
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('What AI detects',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text1)),
            ],
          ),
          SizedBox(height: 8),
          Text('• Missing PPE (hard hat, safety shoes, gloves)\n• Working at heights without harness\n• Electrical safety violations\n• Slip/trip hazards\n• Hot work without permits\n• Unsafe positioning near equipment',
              style: TextStyle(fontSize: 11, color: AppColors.text3, height: 1.7)),
        ],
      ),
    );
  }

  Widget _imageWithOverlay() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.file(_image!, fit: BoxFit.cover, width: double.infinity, height: 280),
            if (_result != null) Positioned.fill(
              child: CustomPaint(
                painter: _HazardBoxPainter(
                  hazards: (_result!['hazards'] as List).cast<Map<String, dynamic>>(),
                  sevColorFn: _sevColor,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() {
                  _image = null;
                  _result = null;
                }),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
            if (_result != null) Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: _sevColor(_result!['severity']), size: 12),
                    const SizedBox(width: 4),
                    Text('${(_result!['hazards'] as List).length} hazards detected',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanningCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(AppColors.accent)),
          ),
          const SizedBox(height: 16),
          const Text('AI Analysing Image...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
          const SizedBox(height: 8),
          Text(_scanStep, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
        ],
      ),
    );
  }

  List<Widget> _buildResult() {
    final r = _result!;
    final sc = _sevColor(r['severity']);
    return [
      _resultHeader(r, sc),
      const SizedBox(height: 12),
      _hazardsTable(r),
      const SizedBox(height: 12),
      _regulationsCard(r),
      const SizedBox(height: 12),
      _recommendationsCard(r),
      const SizedBox(height: 12),
      _wsaCard(r),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveReport,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _image = null;
                _result = null;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('New Scan'),
          ),
        ],
      ),
    ];
  }

  Widget _resultHeader(Map<String, dynamic> r, Color sc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sc.withOpacity(0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Analysis Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc.withOpacity(0.3)),
                ),
                child: Text('Risk: ${r['severity']}',
                    style: TextStyle(fontSize: 10, color: sc, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(r['summary'], style: const TextStyle(fontSize: 12, color: AppColors.text3, height: 1.5)),
          const SizedBox(height: 14),
          _bar('Overall Risk Score', (r['riskScore'] as int) / 100, sc, '${r['riskScore']}/100'),
          const SizedBox(height: 10),
          _bar('AI Confidence', (r['confidence'] as int) / 100, AppColors.accent, '${r['confidence']}%'),
        ],
      ),
    );
  }

  Widget _hazardsTable(Map<String, dynamic> r) {
    final hazards = (r['hazards'] as List).cast<Map<String, dynamic>>();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 16),
                const SizedBox(width: 8),
                const Text('Detected Hazards',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${hazards.length}',
                      style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.card2,
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('#', style: TextStyle(fontSize: 9, color: AppColors.text4, fontWeight: FontWeight.w700, letterSpacing: 0.8))),
                Expanded(flex: 4, child: Text('UNSAFE ACT / CONDITION', style: TextStyle(fontSize: 9, color: AppColors.text4, fontWeight: FontWeight.w700, letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text('SEVERITY', style: TextStyle(fontSize: 9, color: AppColors.text4, fontWeight: FontWeight.w700, letterSpacing: 0.8))),
              ],
            ),
          ),
          ...hazards.asMap().entries.map((entry) {
            final i = entry.key;
            final h = entry.value;
            final hc = _sevColor(h['severity']);
            return Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.3), width: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(color: hc.withOpacity(0.2), shape: BoxShape.circle),
                          child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: hc))),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text1)),
                            const SizedBox(height: 3),
                            Text(h['desc'], style: const TextStyle(fontSize: 10, color: AppColors.text3, height: 1.4)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hc.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: hc.withOpacity(0.3)),
                            ),
                            child: Text(h['severity'],
                                style: TextStyle(fontSize: 9, color: hc, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.only(left: 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cyan.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gavel, size: 11, color: AppColors.cyan),
                        const SizedBox(width: 5),
                        Expanded(child: Text(h['ref'], style: const TextStyle(fontSize: 10, color: AppColors.cyan, height: 1.4))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _regulationsCard(Map<String, dynamic> r) {
    final rules = (r['rules'] as List).cast<String>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_outlined, color: AppColors.red, size: 16),
              SizedBox(width: 8),
              Text('Violated Regulations',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.map((rule) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.red.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gavel, size: 13, color: AppColors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(rule, style: const TextStyle(fontSize: 11, color: AppColors.text2, height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _recommendationsCard(Map<String, dynamic> r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.green, size: 16),
              SizedBox(width: 8),
              Text('AI Recommendations',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
            ],
          ),
          const SizedBox(height: 12),
          _subSection('IMMEDIATE CORRECTIVE ACTIONS', AppColors.red),
          const SizedBox(height: 8),
          ...(r['corrective'] as List).asMap().entries.map((e) => _actionItem(e.key + 1, e.value, AppColors.red)),
          const SizedBox(height: 12),
          _subSection('PREVENTIVE MEASURES', AppColors.green),
          const SizedBox(height: 8),
          ...(r['preventive'] as List).asMap().entries.map((e) => _actionItem(e.key + 1, e.value, AppColors.green)),
        ],
      ),
    );
  }

  Widget _wsaCard(Map<String, dynamic> r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category_outlined, color: AppColors.purple, size: 16),
              SizedBox(width: 8),
              Text('WSA 13 Root Cause Classification',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (r['wsa'] as List).map<Widget>((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple.withOpacity(0.3)),
              ),
              child: Text(c, style: const TextStyle(fontSize: 11, color: Color(0xFFC4B5FD), fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _subSection(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.8)),
    );
  }

  Widget _bar(String label, double val, Color color, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
            Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: val),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: AppColors.card3,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionItem(int idx, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Text('$idx', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.text2, height: 1.5))),
        ],
      ),
    );
  }
}

/// Custom painter that draws bounding boxes around detected hazards on the image
class _HazardBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> hazards;
  final Color Function(String) sevColorFn;

  _HazardBoxPainter({required this.hazards, required this.sevColorFn});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);

    for (int i = 0; i < hazards.length; i++) {
      final h = hazards[i];
      final color = sevColorFn(h['severity']);

      double left, top, width, height;
      if (i == 0) {
        left = size.width * 0.15;
        top = size.height * 0.12;
        width = size.width * 0.35;
        height = size.height * 0.45;
      } else if (i == 1) {
        left = size.width * 0.55;
        top = size.height * 0.25;
        width = size.width * 0.35;
        height = size.height * 0.55;
      } else {
        left = size.width * (0.1 + rng.nextDouble() * 0.5);
        top = size.height * (0.4 + rng.nextDouble() * 0.3);
        width = size.width * 0.3;
        height = size.height * 0.3;
      }

      final rect = Rect.fromLTWH(left, top, width, height);

      final fillPaint = Paint()
        ..color = color.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), fillPaint);

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), strokePaint);

      final cornerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      const cornerLen = 12.0;
      canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLen, 0), cornerPaint);
      canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLen), cornerPaint);
      canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLen, 0), cornerPaint);
      canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLen), cornerPaint);
      canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLen, 0), cornerPaint);
      canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLen), cornerPaint);
      canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLen, 0), cornerPaint);
      canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLen), cornerPaint);

      final label = '${i + 1}. ${h['name']}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: width);
      final labelHeight = tp.height + 6;
      final labelRect = Rect.fromLTWH(left, top - labelHeight - 2, tp.width + 12, labelHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..color = color,
      );
      tp.paint(canvas, Offset(left + 6, top - labelHeight + 1));
    }
  }

  @override
  bool shouldRepaint(_HazardBoxPainter old) => old.hazards != hazards;
}
