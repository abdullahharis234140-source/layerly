import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'main.dart';
import 'paywall.dart';
import 'services.dart';

const fonts = ['Bebas Neue', 'Oswald', 'Pacifico', 'Anton', 'Monoton', 'Righteous', 'Lobster', 'Permanent Marker'];
const freeFonts = 3;
const colors = [Colors.white, Colors.black, Colors.yellow, Colors.orange, Colors.redAccent, Colors.pinkAccent, Colors.cyanAccent, Colors.greenAccent];
const styles = ['Solid', 'Outline', 'Neon', 'Gradient']; // 2,3 = Pro

class TL {
  String text; double x = .5, y = .45, size = .24, rot = 0, op = 1;
  int font = 0, style = 0; Color color = Colors.white;
  TL(this.text);
}

class Editor extends StatefulWidget {
  final String path;
  const Editor({super.key, required this.path});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final key = GlobalKey();
  Uint8List? orig, cut;
  double ar = 1;
  bool busy = true, exporting = false;
  final layers = [TL('CREATE')];
  int sel = 0;
  double _s0 = .2, _r0 = 0;

  TL get cur => layers[sel];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    orig = await File(widget.path).readAsBytes();
    final im = await decodeImageFromList(orig!);
    ar = im.width / im.height;
    setState(() {});
    try {
      final seg = SubjectSegmenter(options: SubjectSegmenterOptions(
        enableForegroundBitmap: true, enableForegroundConfidenceMask: false,
        enableMultipleSubjects: SubjectResultOptions(enableConfidenceMask: false, enableSubjectBitmap: false)));
      final r = await seg.processImage(InputImage.fromFilePath(widget.path));
      cut = r.foregroundBitmap;
      seg.close();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subject detection failed: $e')));
    }
    if (mounted) setState(() => busy = false);
  }

  void pro() => Navigator.push(context, MaterialPageRoute(builder: (_) => const Paywall()));

  TextStyle style(TL t, double w) {
    final b = GoogleFonts.getFont(fonts[t.font], fontSize: t.size * w, color: t.color.withOpacity(t.op), height: 1);
    switch (t.style) {
      case 1: return b.copyWith(color: null, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = t.color);
      case 2: return b.copyWith(shadows: [Shadow(color: t.color, blurRadius: 18), Shadow(color: t.color, blurRadius: 40)]);
      case 3: return b.copyWith(color: null, foreground: Paint()..shader = LinearGradient(colors: [t.color, Colors.pinkAccent, Colors.deepPurpleAccent]).createShader(Rect.fromLTWH(0, 0, w * .8, w * .3)));
      default: return b;
    }
  }

  Future<Uint8List> render(bool isPro) async {
    setState(() => exporting = true);
    await Future.delayed(const Duration(milliseconds: 80));
    final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final im = await b.toImage(pixelRatio: isPro ? 4 : 1.5);
    final d = await im.toByteData(format: ui.ImageByteFormat.png);
    setState(() => exporting = false);
    return d!.buffer.asUint8List();
  }

  Future<void> save(bool share) async {
    final app = context.read<AppState>();
    final bytes = await render(app.pro);
    app.logExport();
    if (share) {
      final f = File('${(await getTemporaryDirectory()).path}/layerly_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(f.path)]);
    } else {
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putImageBytes(bytes);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to gallery')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Editor'),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share), onPressed: busy ? null : () => save(true)),
          IconButton(icon: const Icon(Icons.download_rounded), onPressed: busy ? null : () => save(false)),
        ],
      ),
      body: orig == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(child: Center(child: Stack(alignment: Alignment.center, children: [_canvas(app), if (busy) _loading()]))),
              _panel(app),
            ]),
    );
  }

  Widget _loading() => Container(
        color: Colors.black54,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: kPink),
          const SizedBox(height: 14),
          const Text('Detecting subject...').animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: .4, end: 1),
        ]),
      );

  Widget _canvas(AppState app) => RepaintBoundary(
        key: key,
        child: AspectRatio(
          aspectRatio: ar,
          child: LayoutBuilder(builder: (c, bx) {
            final w = bx.maxWidth, h = bx.maxHeight;
            return ClipRect(
              child: Stack(fit: StackFit.expand, children: [
                Image.memory(orig!, fit: BoxFit.fill),
                for (var i = 0; i < layers.length; i++)
                  Positioned(
                    left: layers[i].x * w, top: layers[i].y * h,
                    child: FractionalTranslation(
                      translation: const Offset(-.5, -.5),
                      child: Transform.rotate(
                        angle: layers[i].rot,
                        child: GestureDetector(
                          onTap: () => setState(() => sel = i),
                          onScaleStart: (_) { sel = i; _s0 = layers[i].size; _r0 = layers[i].rot; },
                          onScaleUpdate: (d) => setState(() {
                            final t = layers[i];
                            t.x += d.focalPointDelta.dx / w;
                            t.y += d.focalPointDelta.dy / h;
                            t.size = (_s0 * d.scale).clamp(.05, .8);
                            t.rot = _r0 + d.rotation;
                          }),
                          child: Container(
                            decoration: sel == i && !exporting
                                ? BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(4)) : null,
                            child: Text(layers[i].text, style: style(layers[i], w)),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (cut != null) IgnorePointer(child: Image.memory(cut!, fit: BoxFit.fill)),
                if (!app.pro)
                  Positioned(right: 8, bottom: 8, child: Text('Made with Layerly', style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 11, shadows: const [Shadow(blurRadius: 4)]))),
              ]),
            );
          }),
        ),
      );

  Widget _panel(AppState app) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(color: Color(0xFF14141F), borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey(sel), initialValue: cur.text,
                  onChanged: (v) => setState(() => cur.text = v),
                  decoration: InputDecoration(filled: true, fillColor: Colors.white10, isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
                ),
              ),
              IconButton(icon: const Icon(Icons.add_circle, color: kPink), onPressed: () {
                if (!app.pro && layers.length >= 2) return pro();
                setState(() { layers.add(TL('TEXT')..y = .3 + .15 * layers.length); sel = layers.length - 1; });
              }),
              if (layers.length > 1)
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() { layers.removeAt(sel); sel = 0; })),
            ]),
            SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: [
              for (var i = 0; i < fonts.length; i++)
                Padding(padding: const EdgeInsets.only(right: 8, top: 6), child: ChoiceChip(
                  label: Text(fonts[i] + (i >= freeFonts && !app.pro ? ' 🔒' : ''), style: GoogleFonts.getFont(fonts[i])),
                  selected: cur.font == i,
                  onSelected: (_) => (i >= freeFonts && !app.pro) ? pro() : setState(() => cur.font = i))),
            ])),
            SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: [
              for (var i = 0; i < styles.length; i++)
                Padding(padding: const EdgeInsets.only(right: 8, top: 6), child: ChoiceChip(
                  label: Text(styles[i] + (i >= 2 && !app.pro ? ' 🔒' : '')), selected: cur.style == i,
                  onSelected: (_) => (i >= 2 && !app.pro) ? pro() : setState(() => cur.style = i))),
              const SizedBox(width: 8),
              for (final c in colors)
                GestureDetector(onTap: () => setState(() => cur.color = c),
                    child: Container(width: 30, height: 30, margin: const EdgeInsets.only(right: 8, top: 8),
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: cur.color == c ? kPink : Colors.white24, width: 3)))),
            ])),
            Row(children: [
              const Icon(Icons.format_size, size: 18),
              Expanded(child: Slider(value: cur.size.clamp(.05, .8), min: .05, max: .8, onChanged: (v) => setState(() => cur.size = v))),
              const Icon(Icons.opacity, size: 18),
              Expanded(child: Slider(value: cur.op, min: .1, max: 1, onChanged: (v) => setState(() => cur.op = v))),
            ]),
          ]),
        ),
      ).animate().slideY(begin: .3, duration: 400.ms).fadeIn();
}
