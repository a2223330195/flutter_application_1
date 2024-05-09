import 'package:flutter/material.dart';
import 'package:school_management_app/Vista/vista_tareas.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';
import 'package:school_management_app/Vista/vista_examenes.dart';
import 'package:school_management_app/Vista/vista_proyectos.dart';
import 'package:school_management_app/Vista/vista_actividades.dart';
import 'package:school_management_app/Vista/vista_calificaciones.dart';
import 'package:school_management_app/Vista/vista_pase_lista.dart'; // Importa las nuevas vistas aquí

class DetalleClase extends StatefulWidget {
  final Clase clase;

  const DetalleClase({super.key, required this.clase});

  @override
  DetalleClaseState createState() => DetalleClaseState();
}

class DetalleClaseState extends State<DetalleClase>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clase.nombre),
        bottom: TabBar(
          isScrollable: true, // Agrega esta línea
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pasar Lista'),
            Tab(text: 'Calificaciones'),
            Tab(text: 'Tareas'),
            Tab(text: 'Exámenes'),
            Tab(text: 'Actividades'),
            Tab(text: 'Proyectos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          VistaPaseList(clase: widget.clase),
          VistaCalificaciones(clase: widget.clase),
          VistaTareas(clase: widget.clase),
          VistaExamenes(clase: widget.clase),
          VistaActividades(clase: widget.clase),
          VistaProyectos(clase: widget.clase),
        ],
      ),
    );
  }
}
