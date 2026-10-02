import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'services.dart';

const kPurple = Color(0xFF7C3AED), kPink = Color(0xFFEC4899), kBg = Color(0xFF0B0B14);
const kGrad = LinearGradient(colors: [kPurple, kPink], begin: Alignment.topLeft, end: Alignment.bottomRight);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => AppState()..init(), child: const LayerlyApp()));
}

class LayerlyApp extends StatelessWidget {
  const LayerlyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Layerly',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(primary: kPurple, secondary: kPink),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        ),
        home: const Splash(),
      );
}

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const Home(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c)));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(gradient: kGrad, borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.layers_rounded, size: 60, color: Colors.white),
            ).animate().scale(duration: 700.ms, curve: Curves.elasticOut).then().shimmer(duration: 900.ms),
            const SizedBox(height: 24),
            Text('Layerly', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w800))
                .animate(delay: 400.ms).fadeIn().slideY(begin: .5),
            Text('Text behind image studio', style: TextStyle(color: Colors.white.withOpacity(.6)))
                .animate(delay: 700.ms).fadeIn(),
          ]),
        ),
      );
}
