import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';

class VistaPaseList extends StatefulWidget {
  final Clase clase;

  const VistaPaseList({super.key, required this.clase});

  @override
  VistaPaseListState createState() => VistaPaseListState();
}

class VistaPaseListState extends State<VistaPaseList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes'
  ];
  DateTime _fechaSeleccionada = DateTime.now();

  Future<void> guardarAsistencia(
      String alumnoId, bool presente, String dia) async {
    final fechaFormateada = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
    final documentId = '$alumnoId-$dia-$fechaFormateada';

    try {
      await _firestore
          .collection('Profesores')
          .doc(widget.clase.profesorId)
          .collection('Clases')
          .doc(widget.clase.id)
          .collection('asistencia')
          .doc(documentId)
          .set({'presente': presente});
    } catch (e) {
      print('Error al guardar la asistencia: $e');
    }
  }

  Future<void> _agregarAlumno() async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final nombreController = TextEditingController();
        return AlertDialog(
          title: const Text('Agregar alumno'),
          content: TextField(
            controller: nombreController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Nombre del alumno',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nombreController.text),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (nombre != null) {
      final alumnoId = _firestore.collection('alumnos').doc().id;
      await _firestore
          .collection('Profesores')
          .doc(widget.clase.profesorId)
          .collection('Clases')
          .doc(widget.clase.id)
          .collection('alumnos')
          .doc(alumnoId)
          .set({'nombre': nombre});
    }
  }

  void _actualizarFecha(DateTime fecha) {
    setState(() {
      _fechaSeleccionada = fecha;
    });
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
            final DateTime fechaActual = DateTime.now();
            final DateTime primerDiaDelMes =
                DateTime(fechaActual.year, fechaActual.month, 1);
            final DateTime ultimoDiaDelMes =
                DateTime(fechaActual.year, fechaActual.month + 1, 0);

            return Column(
              children: [
                CalendarDatePicker(
                  initialDate: _fechaSeleccionada,
                  firstDate: primerDiaDelMes,
                  lastDate: ultimoDiaDelMes,
                  onDateChanged: _actualizarFecha,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('Alumno')),
                      ..._dias.map((dia) => DataColumn(label: Text(dia))),
                    ],
                    rows: alumnos.map((alumno) {
                      final nombreAlumno =
                          (alumno.data() as Map<String, dynamic>)['nombre'] ??
                              '';
                      final alumnoId = alumno.id;
                      return DataRow(
                        cells: [
                          DataCell(Text(nombreAlumno)),
                          ..._dias.map(
                            (dia) => DataCell(
                              StreamBuilder<DocumentSnapshot>(
                                stream: _firestore
                                    .collection('Profesores')
                                    .doc(widget.clase.profesorId)
                                    .collection('Clases')
                                    .doc(widget.clase.id)
                                    .collection('asistencia')
                                    .doc(
                                        '$alumnoId-$dia-${DateFormat('yyyy-MM-dd').format(_fechaSeleccionada)}')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final presente = snapshot.hasData &&
                                          snapshot.data!.data() != null &&
                                          (snapshot.data!.data()
                                                  as Map<String, dynamic>)
                                              .containsKey('presente')
                                      ? (snapshot.data!.data() as Map<String,
                                          dynamic>)['presente'] as bool
                                      : false;
                                  return Checkbox(
                                    value: presente,
                                    onChanged: (bool? newValue) {
                                      guardarAsistencia(
                                          alumnoId, newValue ?? false, dia);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarAlumno,
        child: const Icon(Icons.add),
      ),
    );
  }
}
