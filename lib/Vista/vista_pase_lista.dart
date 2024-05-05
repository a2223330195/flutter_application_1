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
  bool _mostrarCalendario = false;
  Map<String, bool> asistenciaActual = {};

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

      // Actualizar _asistenciaActual
      asistenciaActual[alumnoId] = presente;
    } catch (e) {
      // ignore: avoid_print
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

  void _toggleCalendario() {
    setState(() {
      _mostrarCalendario = !_mostrarCalendario;
    });
  }

  void _actualizarFecha(DateTime fecha) {
    setState(() {
      if (fecha.weekday == DateTime.monday) {
        _fechaSeleccionada = fecha;
      } else {
        _fechaSeleccionada = fecha.subtract(Duration(days: fecha.weekday - 1));
      }
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
                if (_mostrarCalendario)
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
                                  final presente =
                                      asistenciaActual[alumnoId] ?? false;
                                  return GestureDetector(
                                    onTap: () {
                                      final nuevoValor = !presente;
                                      guardarAsistencia(
                                          alumnoId, nuevoValor, dia);
                                    },
                                    child: presente
                                        ? const Icon(Icons.check_box,
                                            color: Colors.green)
                                        : const Icon(
                                            Icons.indeterminate_check_box,
                                            color: Colors.red),
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      onPressed: _toggleCalendario,
                      child: const Icon(Icons.calendar_today),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton(
                      onPressed: () {
                        final alumnos = snapshot.data!.docs;
                        final totalAlumnos = alumnos.length;
                        final alumnosPresentes = asistenciaActual.values
                            .where((presente) => presente)
                            .length;
                        final alumnosAusentes = totalAlumnos - alumnosPresentes;

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Información de asistencia'),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Total de alumnos: $totalAlumnos'),
                                  Text('Alumnos presentes: $alumnosPresentes'),
                                  Text('Alumnos ausentes: $alumnosAusentes'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Icon(Icons.info),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton(
                      onPressed: () {
                        final alumnos = snapshot.data!.docs;
                        String asistenciaTexto = '';
                        for (var alumno in alumnos) {
                          final nombreAlumno = (alumno.data()
                                  as Map<String, dynamic>)['nombre'] ??
                              '';
                          final alumnoId = alumno.id;
                          final presente = asistenciaActual[alumnoId] ?? false;
                          asistenciaTexto +=
                              '$nombreAlumno: ${presente ? 'Presente' : 'Ausente'}\n';
                        }

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Lista de asistencia'),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Text(asistenciaTexto),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cerrar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Aquí puedes implementar la funcionalidad de compartir
                                    // el texto de asistenciaTexto.
                                  },
                                  child: const Text('Compartir'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Icon(Icons.list),
                    ),
                  ],
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
