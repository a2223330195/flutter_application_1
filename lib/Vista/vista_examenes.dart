import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';

class VistaExamenes extends StatefulWidget {
  final Clase clase;

  const VistaExamenes({super.key, required this.clase});

  @override
  VistaExamenesState createState() => VistaExamenesState();
}

class VistaExamenesState extends State<VistaExamenes> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Column(
        children: [
          // Aquí irá el listado de exámenes
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí se abrirá la vista para agregar un nuevo examen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
