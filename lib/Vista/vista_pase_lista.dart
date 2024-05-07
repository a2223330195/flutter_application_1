import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
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

      // Actualiza el estado de la asistencia en la interfaz de usuario
      setState(() {});
    } catch (e) {
      // Manejo de errores
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
      if (fecha.weekday >= DateTime.monday &&
          fecha.weekday <= DateTime.friday) {
        _fechaSeleccionada = fecha;
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Fecha no válida'),
              content: const Text(
                  'Por favor, selecciona un día entre lunes y viernes.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  Future<void> _compartirListaPDF() async {
    final pdf = await _generarPDF();
    final bytes = await pdf.save();
    await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'lista_asistencia.pdf')]);
  }

  Future<pw.Document> _generarPDF() async {
    final asistencias = await _obtenerAsistencias();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(children: [
            pw.Header(
              level: 0,
              child: pw.Text('Lista de Asistencia'),
            ),
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                ['Alumno', ..._dias],
                ...asistencias.map(
                  (asistencia) =>
                      [asistencia['nombre'], ...asistencia['asistencias']],
                )
              ],
            ),
          ]);
        },
      ),
    );

    return pdf;
  }

  Future<List<Map<String, dynamic>>> _obtenerAsistencias() async {
    final alumnosSnapshot = await _firestore
        .collection('Profesores')
        .doc(widget.clase.profesorId)
        .collection('Clases')
        .doc(widget.clase.id)
        .collection('alumnos')
        .get();

    final alumnos = alumnosSnapshot.docs
        .map(
          (doc) => {
            'id': doc.id,
            'nombre': doc.data()['nombre'],
            'asistencias': List.filled(_dias.length, ''),
            'estado':
                -1, // Inicialmente se asume que el alumno no ha sido marcado
          },
        )
        .toList();

    for (final alumno in alumnos) {
      final asistenciasSnapshot = await _firestore
          .collection('Profesores')
          .doc(widget.clase.profesorId)
          .collection('Clases')
          .doc(widget.clase.id)
          .collection('alumnos')
          .doc(alumno['id'])
          .collection('asistencias')
          .get();

      for (final asistencia in asistenciasSnapshot.docs) {
        final dia = asistencia.id.split('-').first;
        final indice = _dias.indexOf(dia);
        final estado = asistencia.data()['estado'];
        alumno['asistencias'][indice] = _asistenciaToString(estado);
        alumno['estado'] = estado; // Actualizar el estado del alumno
      }
    }

    return alumnos.cast<Map<String, dynamic>>();
  }

  String _asistenciaToString(int estado) {
    switch (estado) {
      case -1:
        return '-';
      case 0:
        return 'A';
      case 1:
        return 'P';
      case 2:
        return 'R';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () async {
              final asistencias = await _obtenerAsistencias();
              final totalAlumnos = asistencias.length;
              final presentes = asistencias
                  .where((asistencia) => asistencia['estado'] == 1)
                  .length;
              final ausentes = asistencias
                  .where((asistencia) =>
                      asistencia['estado'] == 0 ||
                      asistencia['estado'] == -1 ||
                      asistencia['estado'] == 2)
                  .length;

              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Información de Asistencia'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total de alumnos: $totalAlumnos'),
                        Text('Presentes: $presentes'),
                        Text('Ausentes: $ausentes'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          const IconButton(
            icon: Icon(Icons.share),
            //onPressed: _compartirListaPDF,
            onPressed: null,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _toggleCalendario,
          ),
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
