import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';

class VistaActividades extends StatefulWidget {
  final Clase clase;

  const VistaActividades({super.key, required this.clase});

  @override
  VistaActividadesState createState() => VistaActividadesState();
}

class VistaActividadesState extends State<VistaActividades> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades'),
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
                .collection('actividades')
                .snapshots(),
            builder: (context, actividadesSnapshot) {
              if (!actividadesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final actividades = actividadesSnapshot.data!.docs;

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
                    ...actividades.map((actividad) => DataColumn(
                          label: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(actividad.data()['nombre']),
                                      content: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              'Puntaje: ${actividad.data()['puntaje']}'),
                                          Text(
                                              'Fecha de entrega: ${actividad.data()['fechaEntrega'].toDate()}'),
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
                              child: Text(
                                  'A${actividades.indexOf(actividad) + 1}'),
                            ),
                          ),
                        )),
                  ],
                  rows: alumnos.map((alumno) {
                    return DataRow(
                      cells: [
                        DataCell(Text(alumno.data()['nombre'])),
                        ...actividades.map((actividad) => DataCell(
                              StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: _firestore
                                    .collection('Profesores')
                                    .doc(widget.clase.profesorId)
                                    .collection('Clases')
                                    .doc(widget.clase.id)
                                    .collection('actividades')
                                    .doc(actividad.id)
                                    .collection('entregas')
                                    .where('alumnoId', isEqualTo: alumno.id)
                                    .snapshots(),
                                builder: (context, entregasSnapshot) {
                                  if (!entregasSnapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }

                                  final entregas = entregasSnapshot.data!.docs;
                                  final entregada = entregas.isNotEmpty &&
                                      entregas.first.data()['entregada'];

                                  return IconButton(
                                    icon: Icon(
                                      entregada
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color:
                                          entregada ? Colors.green : Colors.red,
                                    ),
                                    onPressed: () async {
                                      final actividadRef = _firestore
                                          .collection('Profesores')
                                          .doc(widget.clase.profesorId)
                                          .collection('Clases')
                                          .doc(widget.clase.id)
                                          .collection('actividades')
                                          .doc(actividad.id)
                                          .collection('entregas')
                                          .doc(alumno.id);

                                      await actividadRef.set({
                                        'entregada': !entregada,
                                        'alumnoId': alumno.id
                                      });
                                    },
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
                title: const Text('Agregar Actividad'),
                content: TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre de la actividad',
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
                  title: const Text('Puntaje de la Actividad'),
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
              final fechaEntrega = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (fechaEntrega != null) {
                final actividadRef = _firestore
                    .collection('Profesores')
                    .doc(widget.clase.profesorId)
                    .collection('Clases')
                    .doc(widget.clase.id)
                    .collection('actividades')
                    .doc();
                await actividadRef.set({
                  'nombre': nombre,
                  'puntaje': puntaje,
                  'fechaEntrega': fechaEntrega,
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
