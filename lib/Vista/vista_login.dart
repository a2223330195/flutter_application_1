import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:school_management_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management_app/Vista/vista_clases.dart';
import 'package:school_management_app/Controlador/controlador_authservice.dart';

class VistaLogin extends StatefulWidget {
  const VistaLogin({super.key});

  @override
  VistaLoginState createState() => VistaLoginState();
}

class VistaLoginState extends State<VistaLogin> {
  final AuthService _authService = AuthService();
  bool _isRed = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  void changeColor() {
    setState(() {
      _isRed = !_isRed;
    });
  }

  Future<bool> ignInWithGoogle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final User? user = await _authService.signInWithGoogle();
        if (user != null) {
          String? idToken = await user.getIdToken();
          if (idToken != null) {
            await prefs.setString('idToken', idToken);
            await prefs.setBool('isLoggedIn', true);
            return true;
          }
        }
      }
    } catch (error) {
      logger.log(Level.SEVERE, 'Error en signInWithGoogle: $error');
      if (mounted) {
        showErrorSnackBar('Error al iniciar sesión con Google');
      }
    }
    return false;
  }

  Future<void> saveLoginStateAndNavigate(Widget page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idToken = prefs.getString('idToken');
    if (idToken != null) {
      await _authService.signInWithCustomToken(idToken);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      }
    }
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF53D4FB),
          // appBar: AppBar(
          //   title: const Text('Administrar clases'),
          // ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Image.asset(
                      'lib/assets/imagen/logomain2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  'Toque para iniciar sesión',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Impact',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    bool success = await ignInWithGoogle();
                    if (success) {
                      Navigator.pushReplacement(
                        // ignore: use_build_context_synchronously
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VistaClases(),
                        ),
                      );
                    }
                  },
                  child: Image.asset(
                    'lib/assets/imagen/googleicon.png',
                    width: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
