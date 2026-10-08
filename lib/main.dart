import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config.dart';
import 'models/pintura.dart';
import 'pantallas/pantalla_inicio.dart';
import 'pantallas/pantalla_presentacion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Siempre vertical y a pantalla completa, para que sea más difícil salirse sin querer.
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[DeviceOrientation.portraitUp],
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ColorearApp());
}

class ColorearApp extends StatefulWidget {
  const ColorearApp({super.key});

  @override
  State<ColorearApp> createState() => _EstadoApp();
}

class _EstadoApp extends State<ColorearApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Cuando la app se va a segundo plano o se cierra, se guarda lo pintado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      Pintura.guardarPendientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARVI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF7043),
        scaffoldBackgroundColor: Ajustes.fondoApp,
      ),
      home: Ajustes.mostrarPresentacion
          ? const PantallaPresentacion()
          : const PantallaInicio(),
    );
  }
}
