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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exámenes'),
        automaticallyImplyLeading: false, // Desactiva el botón de retroceso
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('Profesores')
            .doc(widget.clase.profesorId)
            .collection('Clases')
            .doc(widget.clase.id)
            .collection('alumnos')
            .snapshots(),
        builder: (context, alumnosSnapshot) {
          if (!alumnosSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alumnos = alumnosSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('Profesores')
                .doc(widget.clase.profesorId)
                .collection('Clases')
                .doc(widget.clase.id)
                .collection('examenes')
                .snapshots(),
            builder: (context, examenesSnapshot) {
              if (!examenesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final examenes = examenesSnapshot.data!.docs;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(
                      label: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text('Alumno'),
                      ),
                    ),
                    ...examenes.map((examen) => DataColumn(
                          label: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(examen.data()['nombre']),
                                      content: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              'Puntaje: ${examen.data()['puntaje']}'),
                                          Text(
                                              'Fecha: ${examen.data()['fecha'].toDate()}'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cerrar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text('E${examenes.indexOf(examen) + 1}'),
                            ),
                          ),
                        )),
                  ],
                  rows: alumnos.map((alumno) {
                    return DataRow(
                      cells: [
                        DataCell(Text(alumno.data()['nombre'])),
                        ...examenes.map((examen) => DataCell(
                              StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: _firestore
                                    .collection('Profesores')
                                    .doc(widget.clase.profesorId)
                                    .collection('Clases')
                                    .doc(widget.clase.id)
                                    .collection('examenes')
                                    .doc(examen.id)
                                    .collection('calificaciones')
                                    .where('alumnoId', isEqualTo: alumno.id)
                                    .snapshots(),
                                builder: (context, calificacionesSnapshot) {
                                  if (!calificacionesSnapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }

                                  final calificaciones =
                                      calificacionesSnapshot.data!.docs;
                                  final calificacion = calificaciones.isNotEmpty
                                      ? calificaciones.first
                                          .data()['calificacion']
                                      : 0.0;

                                  return GestureDetector(
                                    onTap: () async {
                                      final calificacionController =
                                          TextEditingController(
                                        text: calificacion.toString(),
                                      );

                                      final nuevaCalificacion =
                                          await showDialog<double>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(
                                                'Calificación para ${alumno.data()['nombre']}'),
                                            content: TextField(
                                              controller:
                                                  calificacionController,
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              decoration: const InputDecoration(
                                                hintText:
                                                    'Ingresa la calificación',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context,
                                                    double.parse(
                                                        calificacionController
                                                            .text)),
                                                child: const Text('Aceptar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (nuevaCalificacion != null) {
                                        final calificacionRef = _firestore
                                            .collection('Profesores')
                                            .doc(widget.clase.profesorId)
                                            .collection('Clases')
                                            .doc(widget.clase.id)
                                            .collection('examenes')
                                            .doc(examen.id)
                                            .collection('calificaciones')
                                            .doc(alumno.id);

                                        await calificacionRef.set({
                                          'calificacion': nuevaCalificacion,
                                          'alumnoId': alumno.id,
                                        });
                                      }
                                    },
                                    child: Text(calificacion.toString()),
                                  );
                                },
                              ),
                            )),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nombre = await showDialog<String>(
            context: context,
            builder: (BuildContext context) {
              final nombreController = TextEditingController();
              return AlertDialog(
                title: const Text('Agregar Examen'),
                content: TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre del examen',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, nombreController.text),
                    child: const Text('Aceptar'),
                  ),
                ],
              );
            },
          );
          if (nombre != null) {
            final puntaje = await showDialog<double>(
              context: context,
              builder: (BuildContext context) {
                final puntajeController = TextEditingController();
                return AlertDialog(
                  title: const Text('Puntaje del Examen'),
                  content: TextField(
                    controller: puntajeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Puntaje máximo',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(
                          context, double.parse(puntajeController.text)),
                      child: const Text('Aceptar'),
                    ),
                  ],
                );
              },
            );

            if (puntaje != null) {
              final fecha = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (fecha != null) {
                final examenRef = _firestore
                    .collection('Profesores')
                    .doc(widget.clase.profesorId)
                    .collection('Clases')
                    .doc(widget.clase.id)
                    .collection('examenes')
                    .doc();

                await examenRef.set({
                  'nombre': nombre,
                  'puntaje': puntaje,
                  'fecha': fecha,
                });
              }
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
