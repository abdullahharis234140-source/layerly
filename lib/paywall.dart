import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'services.dart';

class Paywall extends StatelessWidget {
  const Paywall({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final perks = ['All 8+ fonts', 'Neon & gradient text', 'Unlimited text layers', 'HD export (4x)', 'No watermark'];
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, actions: [TextButton(onPressed: app.restore, child: const Text('Restore'))]),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        const Icon(Icons.workspace_premium, size: 70, color: Colors.amber).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
        const SizedBox(height: 10),
        const Text('Layerly Pro', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        for (var i = 0; i < perks.length; i++)
          ListTile(dense: true, leading: const Icon(Icons.check_circle, color: kPink), title: Text(perks[i]))
              .animate(delay: (150 * i).ms).fadeIn().slideX(begin: .2),
        const SizedBox(height: 14),
        if (app.products.isEmpty)
          const Text('Plans load from Google Play / App Store.\nCreate products "layerly_pro_monthly" and "layerly_pro_yearly".',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
        for (final p in app.products)
          Card(
            color: Colors.white10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: p.id.contains('yearly') ? kPink : Colors.white24, width: 2)),
            child: ListTile(
              onTap: () => app.buy(p),
              title: Text(p.id.contains('yearly') ? 'Yearly  (Best value)' : 'Monthly', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(p.description),
              trailing: Text(p.price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: .3),
        if (app.pro) const Padding(padding: EdgeInsets.all(16), child: Text('You are Pro. Thank you!', textAlign: TextAlign.center)),
      ]),
    );
  }
}
