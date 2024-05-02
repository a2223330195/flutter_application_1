import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management_app/Vista/vista_login.dart';
import 'package:school_management_app/Vista/vista_clases.dart';
import 'package:school_management_app/Controlador/controlador_authservice.dart';

final Logger logger = Logger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Configura el logger
  Logger.root.level = Level.ALL; // Muestra todos los mensajes de registro
  Logger.root.onRecord.listen((record) {
    logger.log(record.level,
        '${record.level.name}: ${record.time}: ${record.message}');
  });

// Verifica el estado de inicio de sesión
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String? idToken = prefs.getString('idToken');

  if (idToken != null) {
    // Intenta autenticar al usuario con el token almacenado
    AuthService authService = AuthService();
    try {
      await authService.auth.signInWithCustomToken(idToken);
      isLoggedIn = true;
    } catch (e) {
      // El token no es válido o ha expirado
      isLoggedIn = false;
    }
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Escuela',
      theme: ThemeData(primarySwatch: Colors.red),
      home: isLoggedIn ? const VistaClases() : const VistaLogin(),
    );
  }
}
