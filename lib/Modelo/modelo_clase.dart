import 'package:flutter/material.dart';

class Clase extends StatelessWidget {
  final String nombre;
  final String horario;
  final String profesorId; // Agregar esta línea
  final String id; // Agregar esta línea

  const Clase({
    super.key,
    required this.nombre,
    required this.horario,
    required this.profesorId, // Agregar esta línea
    required this.id, // Agregar esta línea
  });

  static Clase fromMap(Map<String, dynamic> map, String documentId) {
    return Clase(
      nombre: map['Clase'] ?? '',
      horario: map['Horario'] ?? '',
      profesorId: map['profesorId'] ?? '',
      id: documentId,
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
