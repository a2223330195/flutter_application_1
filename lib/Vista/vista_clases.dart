import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_management_app/Vista/vista_login.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';
import 'package:school_management_app/Vista/vista_detalle_clase.dart';
import 'package:school_management_app/Controlador/controlador_nueva_clase.dart';
import 'package:school_management_app/Controlador/controlador_authservice.dart';

class VistaClases extends StatefulWidget {
  const VistaClases({super.key});

  @override
  VistaClasesState createState() => VistaClasesState();
}

class VistaClasesState extends State<VistaClases> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String? _currentUserUid;

  Future<void> _agregarClase() async {
    await _getCurrentUserUid();
    if (_currentUserUid != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NuevaClase()),
      ).then((resultado) {
        if (resultado is Clase) {
          _firestore
              .collection('Profesores')
              .doc(_currentUserUid)
              .collection('Clases')
              .add({
            'Clase': resultado.nombre,
            'Horario': resultado.horario,
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener el UID del usuario actual'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentUserUid().then((_) {
      setState(() {});
    });
  }

  Future<void> _getCurrentUserUid() async {
    _currentUserUid = await _authService.getCurrentUserUid();
  }

  Future<bool> _onWillPop() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Estás seguro?'),
            content: const Text(
                '¿Quieres cerrar la sesión y salir de la aplicación?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  await prefs.remove('idToken');
                  await prefs.setBool('isLoggedIn', false);
                  _authService.signOutGoogle();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const VistaLogin()),
                  );
                },
                child: const Text('Sí'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Clases'),
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _onWillPop,
          ),
        ),
        body: _currentUserUid != null
            ? StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('Profesores')
                    .doc(_currentUserUid)
                    .collection('Clases')
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  return ListView(
                    children:
                        snapshot.data?.docs.map((DocumentSnapshot document) {
                              Clase clase = Clase.fromMap(
                                  document.data() as Map<String, dynamic>);
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            DetalleClase(clase: clase)),
                                  );
                                },
                                child: Card(
                                  child: ListTile(
                                    title: Text(
                                      clase.nombre,
                                      style: const TextStyle(
                                        fontFamily: 'Arial',
                                        fontSize: 20.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    // Agrega aquí cualquier otro campo que necesites mostrar en la lista
                                  ),
                                ),
                              );
                            }).toList() ??
                            [],
                  );
                },
              )
            : const Center(
                child: Text('No se pudo obtener el UID del usuario')),
        floatingActionButton: FloatingActionButton(
          onPressed: _agregarClase,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
