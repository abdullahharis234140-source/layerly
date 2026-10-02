import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'editor.dart';
import 'main.dart';
import 'paywall.dart';
import 'services.dart';

Future<void> pick(BuildContext c, ImageSource s) async {
  final f = await ImagePicker().pickImage(source: s, maxWidth: 2048);
  if (f != null && c.mounted) Navigator.push(c, MaterialPageRoute(builder: (_) => Editor(path: f.path)));
}

class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -.6), radius: 1.2,
            colors: [kPurple.withOpacity(.35), kBg])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                  onLongPress: kDebugMode ? app.debugToggle : null,
                  child: Text('Layerly', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                app.pro
                    ? const Chip(label: Text('PRO'), avatar: Icon(Icons.workspace_premium, size: 18, color: Colors.amber))
                    : FilledButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Paywall())),
                        icon: const Icon(Icons.bolt), label: const Text('Go Pro')),
              ]).animate().fadeIn().slideY(begin: -.3),
              const Spacer(),
              Center(child: _Hero()),
              const Spacer(),
              Text('Put text behind\nanything.', style: GoogleFonts.poppins(fontSize: 34, height: 1.1, fontWeight: FontWeight.w800))
                  .animate().fadeIn(delay: 200.ms).slideX(begin: -.1),
              const SizedBox(height: 8),
              Text('AI detects your subject. Text slips behind it.', style: TextStyle(color: Colors.white.withOpacity(.65)))
                  .animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: _Btn(Icons.photo_library_rounded, 'Gallery', () => pick(context, ImageSource.gallery), true)),
                const SizedBox(width: 12),
                Expanded(child: _Btn(Icons.photo_camera_rounded, 'Camera', () => pick(context, ImageSource.camera), false)),
              ]).animate().fadeIn(delay: 500.ms).slideY(begin: .4),
              const SizedBox(height: 14),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 250, height: 250,
        decoration: BoxDecoration(gradient: kGrad, borderRadius: BorderRadius.circular(36),
            boxShadow: [BoxShadow(color: kPink.withOpacity(.4), blurRadius: 50)]),
        child: Stack(alignment: Alignment.center, children: [
          Text('DEPTH', style: GoogleFonts.anton(fontSize: 78, color: Colors.white)),
          const Positioned(bottom: 0, child: Icon(Icons.person, size: 190, color: Color(0xFF1B1030))),
        ]),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -8, end: 8, duration: 2.seconds, curve: Curves.easeInOut);
}

class _Btn extends StatelessWidget {
  final IconData i; final String t; final VoidCallback f; final bool main;
  const _Btn(this.i, this.t, this.f, this.main);
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: f, borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(gradient: main ? kGrad : null, color: main ? null : Colors.white10, borderRadius: BorderRadius.circular(18)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i), const SizedBox(width: 8), Text(t, style: const TextStyle(fontWeight: FontWeight.w700))]),
        ),
      );
}
