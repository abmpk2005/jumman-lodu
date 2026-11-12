import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/home_screen.dart';

const String supabaseUrl = 'https://tjagciqfcijvszqtsxhr.supabase.co';
const String supabaseAnonKey = 'sb_publishable_jkd8rKF0gJHgml6kxmOxig_1mWaF7Sm';
const String masterAdminPin = '7742';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } catch (_) {}
  runApp(const JummanLudoApp());
}

class JummanLudoApp extends StatelessWidget {
  const JummanLudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'jumman Ludo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.hindSiliguriTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF19011F),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    final userId = prefs.getString('user_id');

    if (phone != null && userId != null) {
      try {
        final p = await Supabase.instance.client.from('profiles').select().eq('phone_number', phone).maybeSingle();
        if (p != null && p['is_banned'] == true) {
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BannedUserScreen()));
          return;
        }
      } catch (_) {}
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(phone: phone, userId: userId)));
    } else {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF4A0A58), Color(0xFF19011F)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino, size: 90, color: Color(0xFFFFD700)),
            SizedBox(height: 16),
            Text("JUMMAN LUDO", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
            Text("★ LUDO KING MODULAR PRO ★", style: TextStyle(color: Colors.amberAccent, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 35),
            CircularProgressIndicator(color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}

class BannedUserScreen extends StatelessWidget {
  const BannedUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        color: const Color(0xFF24022B),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_flipped, size: 90, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text("অ্যাকাউন্ট স্থগিত (Blocked)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                "নিয়ম লঙ্ঘনের কারণে আপনার আইডিটি সাময়িকভাবে ব্লক করা হয়েছে। পুনরায় সক্রিয় করতে সাপোর্টে যোগাযোগ করুন।",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), minimumSize: const Size(double.infinity, 50)),
                icon: const Icon(Icons.chat),
                label: const Text("WhatsApp সাপোর্টে কথা বলুন"),
                onPressed: () async {
                  final uri = Uri.parse("https://wa.me/8801774229222?text=${Uri.encodeComponent('আমার অ্যাকাউন্ট ব্লক করা হয়েছে, দয়া করে আনব্লক করুন।')}");
                  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    final n = _name.text.trim();
    final p = _phone.text.trim();
    if (n.isEmpty || p.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("সঠিক নাম ও ১১ ডিজিটের মোবাইল নম্বর দিন")));
      return;
    }
    setState(() => _loading = true);
    try {
      final sb = Supabase.instance.client;
      final existing = await sb.from('profiles').select().eq('phone_number', p).maybeSingle();
      if (existing != null && existing['is_banned'] == true) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BannedUserScreen()));
        return;
      }
      String uid = existing != null ? existing['id'].toString() : 'USR_$p';
      if (existing == null) {
        final genId = "JL-${10000 + DateTime.now().millisecond}";
        await sb.from('profiles').insert({'id': uid, 'player_id': genId, 'full_name': n, 'phone_number': p, 'total_matches': 0, 'matches_won': 0, 'is_banned': false});
        await sb.from('wallet_accounts').insert({'user_id': uid, 'balance': 50.0});
      }
      final pr = await SharedPreferences.getInstance();
      await pr.setString('user_phone', p);
      await pr.setString('user_name', n);
      await pr.setString('user_id', uid);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(phone: p, userId: uid)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("লগইন ত্রুটি: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.casino, size: 75, color: Colors.amber),
              const SizedBox(height: 12),
              const Text("জুমান লুডুতে স্বাগতম!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              TextField(controller: _name, decoration: InputDecoration(hintText: "পূর্ণ নাম", filled: true, fillColor: const Color(0xFF3D0947), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 14),
              TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: "মোবাইল নম্বর", filled: true, fillColor: const Color(0xFF3D0947), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: _loading ? null : _login,
                child: _loading ? const CircularProgressIndicator(color: Colors.black) : const Text("প্রবেশ করুন", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
