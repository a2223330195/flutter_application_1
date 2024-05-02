import 'package:flutter/material.dart';

class Clase extends StatelessWidget {
  final String nombre;
  final String horario;

  const Clase({super.key, required this.nombre, required this.horario});

  static Clase fromMap(Map<String, dynamic> map) {
    return Clase(
      nombre: map['Clase'],
      horario: map[
          'Horario'], // Asegúrate de que 'schedule' es el nombre correcto del campo en tu base de datos
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.book),
        title: Text(nombre),
        subtitle: Text(horario),
      ),
    );
  }
}
