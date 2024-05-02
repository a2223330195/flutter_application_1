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
        final User? user = (await _authService.signInWithGoogle());
        if (user != null) {
          String? idToken = await user.getIdToken();
          if (idToken != null) {
            await prefs.setString('idToken', idToken);
          }
        }
        await prefs.setBool('isLoggedIn', true);
        return true;
      } else {
        await prefs.setBool('isLoggedIn', false);
        if (mounted) {
          showErrorSnackBar('Inicio de sesión con Google cancelado');
        }
      }
    } catch (error) {
      await prefs.setBool('isLoggedIn', false);
      logger.log(Level.SEVERE, 'Error en signInWithGoogle: $error');
      if (mounted) {
        showErrorSnackBar('Error al iniciar sesión con Google');
      }
    }
    return false;
  }

  Future<void> saveLoginStateAndNavigate(Widget page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    String? idToken = await _authService.auth.currentUser?.getIdToken();
    if (idToken != null) {
      await prefs.setString('idToken', idToken);
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
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
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Administrar clases'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.all(20.0),
                  child: Image.asset('lib/assets/imagen/imagen01.jpg'),
                ),
                const Text(
                  'Bienvenido',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    signInWithGoogle().then((success) {
                      if (success) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return const VistaClases();
                            },
                          ),
                        );
                      }
                    });
                  },
                  child: const Text('Sign in with Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
