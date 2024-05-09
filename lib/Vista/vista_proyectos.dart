import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';

class VistaProyectos extends StatefulWidget {
  final Clase clase;

  const VistaProyectos({super.key, required this.clase});

  @override
  VistaProyectosState createState() => VistaProyectosState();
}

class VistaProyectosState extends State<VistaProyectos> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
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
                .collection('proyectos')
                .snapshots(),
            builder: (context, proyectosSnapshot) {
              if (!proyectosSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final proyectos = proyectosSnapshot.data!.docs;

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
                    ...proyectos.map((proyecto) => DataColumn(
                          label: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(proyecto.data()['nombre']),
                                      content: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              'Puntaje: ${proyecto.data()['puntaje']}'),
                                          Text(
                                              'Fecha de entrega: ${proyecto.data()['fechaEntrega'].toDate()}'),
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
                              child:
                                  Text('P${proyectos.indexOf(proyecto) + 1}'),
                            ),
                          ),
                        )),
                  ],
                  rows: alumnos.map((alumno) {
                    return DataRow(
                      cells: [
                        DataCell(Text(alumno.data()['nombre'])),
                        ...proyectos.map((proyecto) => DataCell(
                              StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: _firestore
                                    .collection('Profesores')
                                    .doc(widget.clase.profesorId)
                                    .collection('Clases')
                                    .doc(widget.clase.id)
                                    .collection('proyectos')
                                    .doc(proyecto.id)
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
                                      final proyectoRef = _firestore
                                          .collection('Profesores')
                                          .doc(widget.clase.profesorId)
                                          .collection('Clases')
                                          .doc(widget.clase.id)
                                          .collection('proyectos')
                                          .doc(proyecto.id)
                                          .collection('entregas')
                                          .doc(alumno.id);

                                      await proyectoRef.set({
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
                title: const Text('Agregar Proyecto'),
                content: TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre del proyecto',
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
                  title: const Text('Puntaje del Proyecto'),
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
                final proyectoRef = _firestore
                    .collection('Profesores')
                    .doc(widget.clase.profesorId)
                    .collection('Clases')
                    .doc(widget.clase.id)
                    .collection('proyectos')
                    .doc();

                await proyectoRef.set({
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
