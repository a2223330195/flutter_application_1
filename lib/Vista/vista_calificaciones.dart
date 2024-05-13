import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_app/Modelo/modelo_clase.dart';
import 'package:school_management_app/Modelo/modelo_ponderacion.dart';

class VistaCalificaciones extends StatefulWidget {
  final Clase clase;

  const VistaCalificaciones({super.key, required this.clase});

  @override
  VistaCalificacionesState createState() => VistaCalificacionesState();
}

class VistaCalificacionesState extends State<VistaCalificaciones> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Ponderacion> _ponderaciones = [
    Ponderacion(nombre: 'Tareas', valor: 0.3),
    Ponderacion(nombre: 'Exámenes', valor: 0.4),
    Ponderacion(nombre: 'Actividades', valor: 0.2),
    Ponderacion(nombre: 'Asistencia', valor: 0.1),
  ];
  double sumaPonderaciones = 1.0;

  Future<void> _modificarPonderaciones() async {
    final ponderacionesModificadas = await showDialog<List<Ponderacion>>(
      context: context,
      builder: (BuildContext context) {
        final controladoresTexto = _ponderaciones
            .map((ponderacion) =>
                TextEditingController(text: ponderacion.valor.toString()))
            .toList();

        return AlertDialog(
          title: const Text('Modificar Ponderaciones'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _ponderaciones.asMap().entries.map((entry) {
              final ponderacion = entry.value;
              final controladorTexto = controladoresTexto[entry.key];
              return TextField(
                controller: controladorTexto,
                decoration: InputDecoration(
                  labelText: ponderacion.nombre,
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final valoresPonderaciones = <Ponderacion>[];
                double sumaPonderaciones = 0.0;

                for (int i = 0; i < _ponderaciones.length; i++) {
                  final valorPonderacion =
                      double.tryParse(controladoresTexto[i].text) ?? 0.0;
                  sumaPonderaciones += valorPonderacion;
                  valoresPonderaciones.add(Ponderacion(
                      nombre: _ponderaciones[i].nombre,
                      valor: valorPonderacion));
                }

                if (sumaPonderaciones == 1.0) {
                  Navigator.pop(context, valoresPonderaciones);
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: const Text(
                            'La suma de las ponderaciones debe ser igual a 1.0'),
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
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (ponderacionesModificadas != null) {
      setState(() {
        _ponderaciones.clear();
        _ponderaciones.addAll(ponderacionesModificadas);
      });
    }
  }

  Future<Map<String, double>> _obtenerCalificacionesTareas() async {
    final Map<String, double> calificacionesTareas = {};

    final tareasSnapshot = await _firestore
        .collection('Profesores')
        .doc(widget.clase.profesorId)
        .collection('Clases')
        .doc(widget.clase.id)
        .collection('tareas')
        .get();

    for (final tarea in tareasSnapshot.docs) {
      final entregasSnapshot =
          await tarea.reference.collection('entregas').get();

      for (final entrega in entregasSnapshot.docs) {
        final alumnoId = entrega.data()['alumnoId'];
        final entregada = entrega.data()['entregada'];

        if (entregada) {
          calificacionesTareas[alumnoId] = tarea.data()['puntaje'];
        } else {
          calificacionesTareas[alumnoId] = 0.0;
        }
      }
    }

    return calificacionesTareas;
  }

  Future<Map<String, double>> _obtenerCalificacionesExamenes() async {
    final Map<String, double> calificacionesExamenes = {};

    final examenesSnapshot = await _firestore
        .collection('Profesores')
        .doc(widget.clase.profesorId)
        .collection('Clases')
        .doc(widget.clase.id)
        .collection('examenes')
        .get();

    for (final examen in examenesSnapshot.docs) {
      final calificacionesSnapshot =
          await examen.reference.collection('calificaciones').get();

      for (final calificacion in calificacionesSnapshot.docs) {
        final alumnoId = calificacion.data()['alumnoId'];
        final calificacionAlumno = calificacion.data()['calificacion'];

        calificacionesExamenes[alumnoId] =
            (calificacionesExamenes[alumnoId] ?? 0.0) + calificacionAlumno;
      }
    }

    return calificacionesExamenes;
  }

  Future<Map<String, double>> _obtenerCalificacionesActividades() async {
    final Map<String, double> calificacionesActividades = {};

    final actividadesSnapshot = await _firestore
        .collection('Profesores')
        .doc(widget.clase.profesorId)
        .collection('Clases')
        .doc(widget.clase.id)
        .collection('actividades')
        .get();

    for (final actividad in actividadesSnapshot.docs) {
      final entregasSnapshot =
          await actividad.reference.collection('entregas').get();

      for (final entrega in entregasSnapshot.docs) {
        final alumnoId = entrega.data()['alumnoId'];
        final entregada = entrega.data()['entregada'];

        if (entregada) {
          calificacionesActividades[alumnoId] = actividad.data()['puntaje'];
        } else {
          calificacionesActividades[alumnoId] = 0.0;
        }
      }
    }

    return calificacionesActividades;
  }

  Future<Map<String, double>> _obtenerCalificacionesAsistencia() async {
    final Map<String, double> calificacionesAsistencia = {};

    final alumnosSnapshot = await _firestore
        .collection('Profesores')
        .doc(widget.clase.profesorId)
        .collection('Clases')
        .doc(widget.clase.id)
        .collection('alumnos')
        .get();

    for (final alumno in alumnosSnapshot.docs) {
      final alumnoId = alumno.id;
      final asistenciasSnapshot =
          await alumno.reference.collection('asistencias').get();

      final totalAsistencias = asistenciasSnapshot.size;
      final asistenciasPresente = asistenciasSnapshot.docs
          .where((doc) => doc.data()['estado'] == 1)
          .length;

      final porcentajeAsistencia =
          totalAsistencias > 0 ? asistenciasPresente / totalAsistencias : 0.0;

      calificacionesAsistencia[alumnoId] = porcentajeAsistencia;
    }

    return calificacionesAsistencia;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Calificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _modificarPonderaciones,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerCalificacionesFinales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final calificacionesFinales = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Alumno')),
                  DataColumn(label: Text('Calificación Tareas')),
                  DataColumn(label: Text('Calificación Exámenes')),
                  DataColumn(label: Text('Calificación Actividades')),
                  DataColumn(label: Text('Calificación Asistencia')),
                  DataColumn(label: Text('Calificación Final')),
                ],
                rows: calificacionesFinales.map((alumno) {
                  return DataRow(
                    cells: [
                      DataCell(Text(alumno['nombre'])),
                      DataCell(Text(
                          alumno['calificacionTareas'].toStringAsFixed(2))),
                      DataCell(Text(
                          alumno['calificacionExamenes'].toStringAsFixed(2))),
                      DataCell(Text(alumno['calificacionActividades']
                          .toStringAsFixed(2))),
                      DataCell(Text(
                          alumno['calificacionAsistencia'].toStringAsFixed(2))),
                      DataCell(
                          Text(alumno['calificacionFinal'].toStringAsFixed(2))),
                    ],
                  );
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _obtenerCalificacionesFinales() async {
    final calificacionesTareas = await _obtenerCalificacionesTareas();
    final calificacionesExamenes = await _obtenerCalificacionesExamenes();
    final calificacionesActividades = await _obtenerCalificacionesActividades();
    final calificacionesAsistencia = await _obtenerCalificacionesAsistencia();

    final alumnosSnapshot = await _firestore
        .collection('Profesores')
        .doc(widget.clase.profesorId)
        .collection('Clases')
        .doc(widget.clase.id)
        .collection('alumnos')
        .get();

    final calificacionesFinales = <Map<String, dynamic>>[];

    for (final alumno in alumnosSnapshot.docs) {
      final alumnoId = alumno.id;
      final nombre = alumno.data()['nombre'];

      final calificacionTareas = calificacionesTareas[alumnoId] ?? 0.0;
      final calificacionExamenes = calificacionesExamenes[alumnoId] ?? 0.0;
      final calificacionActividades =
          calificacionesActividades[alumnoId] ?? 0.0;
      final calificacionAsistencia = calificacionesAsistencia[alumnoId] ?? 0.0;

      final calificacionFinal = (calificacionTareas * _ponderaciones[0].valor) +
          (calificacionExamenes * _ponderaciones[1].valor) +
          (calificacionActividades * _ponderaciones[2].valor) +
          (calificacionAsistencia * _ponderaciones[3].valor);

      calificacionesFinales.add({
        'nombre': nombre,
        'calificacionTareas': calificacionTareas,
        'calificacionExamenes': calificacionExamenes,
        'calificacionActividades': calificacionActividades,
        'calificacionAsistencia': calificacionAsistencia,
        'calificacionFinal': calificacionFinal,
      });
    }

    return calificacionesFinales;
  }
}
