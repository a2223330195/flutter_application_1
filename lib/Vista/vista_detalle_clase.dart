import 'package:flutter/material.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';

class DetalleClase extends StatelessWidget {
  final Clase clase;

  const DetalleClase({super.key, required this.clase});

  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Estás seguro?'),
            content: const Text('¿Quieres salir de la pantalla de detalles?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(clase.nombre),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Horario: ${clase.horario}',
                  style: Theme.of(context).textTheme.titleLarge),
              // Agrega aquí más información sobre la clase
            ],
          ),
        ),
      ),
    );
  }
}
