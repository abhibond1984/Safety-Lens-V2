import 'package:flutter/material.dart';
import '../main.dart';
import '../services/local_ai.dart';

class RulesTab extends StatefulWidget {
  const RulesTab({super.key});
  @override
  State<RulesTab> createState() => _RulesTabState();
}

class _RulesTabState extends State<RulesTab> {
  final _msgs = <_Msg>[
    _Msg(true, 'Hello! I\'m your SAIL Safety Assistant — fully offline.\n\nTry asking about: PPE, LOTO, confined space, working at height, electrical safety, gas safety, WSA 13, or Factories Act.'),
  ];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _thinking = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(false, text));
      _thinking = true;
    });
    _scrollDown();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _msgs.add(_Msg(true, LocalAI.chat(text)));
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Safety Rules & AI Chat'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
            ),
            child: const Text('✓ Offline', style: TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _msgs.length + (_thinking ? 1 : 0),
              itemBuilder: (_, i) {
                if (_thinking && i == _msgs.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.card2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
                          SizedBox(width: 8),
                          Text('Searching offline database...', style: TextStyle(fontSize: 11, color: AppColors.text3)),
                        ],
                      ),
                    ),
                  );
                }
                final msg = _msgs[i];
                return Align(
                  alignment: msg.isAI ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    decoration: BoxDecoration(
                      color: msg.isAI ? AppColors.card2 : AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(msg.isAI ? 3 : 14),
                        bottomRight: Radius.circular(msg.isAI ? 14 : 3),
                      ),
                      border: Border.all(
                        color: msg.isAI ? AppColors.border : AppColors.accent.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(msg.text, style: const TextStyle(fontSize: 12, color: AppColors.text2, height: 1.55)),
                  ),
                );
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['PPE requirements', 'LOTO procedure', 'Confined space', 'Hot work permit', 'Working at height', 'Gas safety', 'WSA 13 causes', 'Factories Act']
                  .map((t) => GestureDetector(
                        onTap: () => _send(t),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.card2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: Text(t, style: const TextStyle(fontSize: 10, color: AppColors.text3)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
            decoration: const BoxDecoration(
              color: AppColors.bg2,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(fontSize: 12, color: AppColors.text1),
                    decoration: const InputDecoration(
                      hintText: 'Ask a safety question...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _send(_ctrl.text),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.accent, AppColors.purple]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final bool isAI;
  final String text;
  _Msg(this.isAI, this.text);
}
