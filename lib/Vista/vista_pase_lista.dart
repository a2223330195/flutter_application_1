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

  Future<void> guardarAsistencia(
      String alumnoId, int estado, String dia) async {
    final fechaFormateada = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
    final documentId = '$dia-$fechaFormateada';

    try {
      await _firestore
          .collection('Profesores')
          .doc(widget.clase.profesorId)
          .collection('Clases')
          .doc(widget.clase.id)
          .collection('alumnos')
          .doc(alumnoId)
          .collection('asistencias')
          .doc(documentId)
          .set({'estado': estado});
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
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _toggleCalendario,
          ),
          // Otros IconButtons aquí
        ],
      ),
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
                                    .collection('alumnos')
                                    .doc(alumnoId)
                                    .collection('asistencias')
                                    .doc(
                                        '$dia-${DateFormat('yyyy-MM-dd').format(_fechaSeleccionada)}')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final estado = snapshot.hasData &&
                                          snapshot.data!.data() != null
                                      ? (snapshot.data!.data() as Map<String,
                                              dynamic>)['estado'] ??
                                          0
                                      : 0;
                                  return GestureDetector(
                                    onTap: () {
                                      final nuevoValor = (estado + 1) % 3;
                                      guardarAsistencia(
                                          alumnoId, nuevoValor, dia);
                                    },
                                    child: estado == 0
                                        ? const Icon(Icons.remove,
                                            color: Colors.grey)
                                        : estado == 1
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
