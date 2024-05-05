import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';

class VistaTareas extends StatefulWidget {
  final Clase clase;

  const VistaTareas({super.key, required this.clase});

  @override
  VistaTareasState createState() => VistaTareasState();
}

class VistaTareasState extends State<VistaTareas> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Column(
        children: [
          // Aquí irá el listado de tareas
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí se abrirá la vista para agregar una nueva tarea
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
