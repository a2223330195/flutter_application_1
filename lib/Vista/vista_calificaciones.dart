import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';

class VistaCalificaciones extends StatefulWidget {
  final Clase clase;

  const VistaCalificaciones({super.key, required this.clase});

  @override
  VistaCalificacionesState createState() => VistaCalificacionesState();
}

class VistaCalificacionesState extends State<VistaCalificaciones> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _unidades = [
    'Unidad 1',
    'Unidad 2',
    'Unidad 3',
    'Unidad 4',
    'Unidad 5',
    'Final'
  ];

  Future<void> guardarCalificacion(
      String alumnoId, String unidad, double calificacion) async {
    final claseId = widget.clase.id;

    try {
      await _firestore
          .collection('Profesores')
          .doc(widget.clase.profesorId)
          .collection('Clases')
          .doc(claseId)
          .collection('calificaciones')
          .doc('$alumnoId-$unidad')
          .set({'calificacion': calificacion});
    } catch (e) {
      // ignore: avoid_print
      print('Error al guardar la calificación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('Profesores')
            .doc(widget.clase.profesorId)
            .collection('Clases')
            .doc(widget.clase.id)
            .collection('alumnos')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final alumnos = snapshot.data!.docs;
            return Column(
              children: [
                DataTable(
                  columns: [
                    const DataColumn(label: Text('Alumno')),
                    ..._unidades
                        .map((unidad) => DataColumn(label: Text(unidad))),
                  ],
                  rows: alumnos.map((alumno) {
                    final nombre = alumno['nombre'];
                    return DataRow(
                      cells: [
                        DataCell(Text(nombre)),
                        ..._unidades.map(
                          (unidad) => DataCell(
                            TextField(
                              onChanged: (valor) {
                                if (valor.isNotEmpty) {
                                  final calificacion = double.parse(valor);
                                  guardarCalificacion(
                                      alumno.id, unidad, calificacion);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
