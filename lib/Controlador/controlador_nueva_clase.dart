import 'package:flutter/material.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';

class NuevaClase extends StatefulWidget {
  const NuevaClase({super.key});

  @override
  NuevaClaseState createState() => NuevaClaseState();
}

class NuevaClaseState extends State<NuevaClase> {
  final nombreController = TextEditingController();
  final horarioController = TextEditingController();

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
            onPressed: () {
              Navigator.pop(
                context,
                Clase(
                  nombre: nombreController.text,
                  horario: horarioController.text,
                ),
              );
            },
            child: const Text('Crear Clase'),
          ),
        ],
      ),
    );
  }
}
