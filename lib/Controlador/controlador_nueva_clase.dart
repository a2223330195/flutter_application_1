import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Importa la biblioteca uuid
import 'package:school_management_app/Modelo/modelo_clase.dart';
import 'package:school_management_app/Controlador/controlador_authservice.dart';

class NuevaClase extends StatefulWidget {
  const NuevaClase({super.key});

  @override
  NuevaClaseState createState() => NuevaClaseState();
}

class NuevaClaseState extends State<NuevaClase> {
  final nombreController = TextEditingController();
  final horarioController = TextEditingController();
  final AuthService _authService = AuthService(); // Instancia del AuthService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Clase'),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
            ),
          ),
          TextField(
            controller: horarioController,
            decoration: const InputDecoration(
              labelText: 'Horario',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              String? currentUserUid = await _authService.getCurrentUserUid();
              if (currentUserUid != null) {
                String claseId = const Uuid().v4(); // Genera un ID único
                Navigator.pop(
                  // ignore: use_build_context_synchronously
                  context,
                  Clase(
                    id: claseId,
                    profesorId: currentUserUid,
                    nombre: nombreController.text,
                    horario: horarioController.text,
                  ),
                );
              } else {
                // Maneja el caso en el que no se pueda obtener el currentUserUid
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('No se pudo obtener el UID del usuario actual'),
                  ),
                );
              }
            },
            child: const Text('Crear Clase'),
          ),
        ],
      ),
    );
  }
}
