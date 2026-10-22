import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:colorear_ninos/app/ajustes_app.dart';
import 'package:colorear_ninos/comun/barra_juego.dart';
import 'package:colorear_ninos/comun/celebracion.dart';
import 'package:colorear_ninos/comun/sonidos.dart';
import 'package:colorear_ninos/comun/titulo_colores.dart';
import 'package:colorear_ninos/comun/voz.dart';
import 'package:colorear_ninos/juegos/burbujas/burbuja.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_papas.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';

/// El juego "Burbujas" (Revienta las burbujas).
///
/// Cada nivel:
///  1. Sale el cartel "NIVEL 3" y empiezan a salir burbujas, de a poco, por
///     los cuatro lados de la pantalla.
///  2. Flotan por toda la pantalla, cada una a su velocidad, cambiando de
///     dirección y rebotando en los bordes y entre ellas.
///  3. Con un toque revientan: "¡POP!", gotitas, papelitos y estrellitas.
///     Hay tipos especiales (súper, animalito, mega, rápidas, arcoíris):
///     ver burbujas_ajustes.dart.
///  4. Arriba se ve cuántas lleva y cuántas faltan. Cuando revienta todas,
///     un festejo corto (o la celebración grande cada 5 niveles) y empieza
///     el nivel siguiente. Los niveles no se acaban nunca, y el juego
///     recuerda en qué nivel va.
///
/// Para que vaya fluido, las burbujas se dibujan todas juntas en un solo
/// dibujo que se repinta en cada cuadro (sin rehacer la pantalla).
///
/// La orejita de arriba repite lo que hay que hacer.
/// Lo que se puede cambiar está en burbujas_ajustes.dart.
class BurbujasJuego extends StatefulWidget {
  const BurbujasJuego({super.key, this.nivelInicial, this.semilla});

  /// En qué nivel empieza. Si no se dice, en el que quedó guardado.
  final int? nivelInicial;

  /// Para las pruebas: con el mismo número las burbujas salen siempre
  /// igual. Sin número, cada vez es distinto.
  final int? semilla;

  @override
  State<BurbujasJuego> createState() => EstadoBurbujasJuego();
}

class EstadoBurbujasJuego extends State<BurbujasJuego>
    with TickerProviderStateMixin {
  late final math.Random _azar = math.Random(widget.semilla);

  /// Avisa en cada cuadro de la pantalla (unas 60 veces por segundo) para
  /// mover las burbujas.
  late final Ticker _reloj = createTicker(_cadaCuadro);

  /// Cambia en cada cuadro: el dibujo de las burbujas se repinta solo.
  final ValueNotifier<int> _cuadro = ValueNotifier<int>(0);

  /// El cartel grande ("NIVEL 3", "¡MUY BIEN!").
  late final AnimationController _cartel = AnimationController(vsync: this);
  String _textoCartel = '';
  double _segundosCartel = 1;

  /// Los colores de las burbujas (los de burbujas_ajustes.dart que existen
  /// en la lista de colores de la app).
  final List<Color> _colores = <Color>[
    for (final nombre in AjustesBurbujas.colores)
      if (AjustesApp.colorLlamado(nombre) != null)
        AjustesApp.colorLlamado(nombre)!.color,
  ];

  /// Segundos desde que entró al juego.
  double _ahora = 0;

  /// El tamaño de la zona donde flotan las burbujas.
  Size? _tam;

  int _numeroNivel = 0; // 0 = todavía no empezó
  PlanNivel? _plan;
  final List<Burbuja> _burbujas = <Burbuja>[];
  final List<Estallido> _estallidos = <Estallido>[];
  final List<AnimalLibre> _animales = <AnimalLibre>[];

  /// Las que revientan solas después de la arcoíris (cuándo, y cuál).
  final List<(double, Burbuja)> _cadena = <(double, Burbuja)>[];

  /// Las que faltan por salir en este nivel.
  List<TipoBurbuja> _porSalir = <TipoBurbuja>[];
  int _reventadas = 0; // en este nivel
  int _total = 0; // las que hay que reventar en este nivel
  int _estrellas = 0; // en total
  double _proximaSalida = 0;
  bool _terminoNivel = false;
  bool _celebrando = false;
  int _siguienteId = 0;
  int _ultimoLado = -1;
  int _turnoPop = 0;
  Color? _ultimoColor;

  // Para las pruebas.
  @visibleForTesting
  List<Burbuja> get burbujas => List<Burbuja>.unmodifiable(_burbujas);
  @visibleForTesting
  PlanNivel? get plan => _plan;
  @visibleForTesting
  int get nivel => _numeroNivel;
  @visibleForTesting
  int get reventadas => _reventadas;
  @visibleForTesting
  int get total => _total;
  @visibleForTesting
  int get animalesVolando => _animales.length;

  @override
  void initState() {
    super.initState();
    Voz.preparar();
    Sonidos.preparar(<String>[
      ...AjustesBurbujas.sonidosPop,
      AjustesBurbujas.sonidoSuperToque,
      AjustesBurbujas.sonidoSuperPop,
      AjustesBurbujas.sonidoAnimalito,
    ]);
    _reloj.start();
    _arrancar();
  }

  @override
  void dispose() {
    _reloj.dispose();
    _cartel.dispose();
    _cuadro.dispose();
    super.dispose();
  }

  double _entre(double a, double b) => a + (b - a) * _azar.nextDouble();

  void _decirQueHacer() => Voz.decir(AjustesBurbujas.vozInicio);

  String _vozDe(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.superBurbuja => AjustesBurbujas.vozSuper,
        TipoBurbuja.animalito => AjustesBurbujas.vozAnimalito,
        TipoBurbuja.mega => AjustesBurbujas.vozMega,
        TipoBurbuja.rapida => AjustesBurbujas.vozRapida,
        TipoBurbuja.arcoiris => AjustesBurbujas.vozArcoiris,
        _ => '',
      };

  // ------------------------------------------------------- 1. cada nivel

  /// Empieza en el nivel guardado (o en el que se pidió).
  Future<void> _arrancar() async {
    final nivel = widget.nivelInicial ?? await ProgresoBurbujas.cargar();
    if (!mounted) return;
    _empezarNivel(nivel, alEntrar: true);
  }

  void _empezarNivel(int numero, {bool alEntrar = false}) {
    final plan = PlanNivel.para(numero, _azar);
    setState(() {
      _numeroNivel = plan.numero;
      _plan = plan;
      _porSalir = plan.orden(_azar);
      _total = plan.total;
      _burbujas.clear();
      _cadena.clear();
      _reventadas = 0;
      _terminoNivel = false;
      _proximaSalida = _ahora + 0.5;
    });
    ProgresoBurbujas.guardar(plan.numero);
    _mostrarCartel('NIVEL ${plan.numero}', AjustesBurbujas.segundosCartelNivel);

    // La voz: al entrar, qué hacer; en cada nivel, su número y lo nuevo.
    final nuevo = plan.nuevos.isEmpty ? null : _vozDe(plan.nuevos.first);
    final numeroNivel =
        AjustesBurbujas.vozNivel.replaceAll('{nivel}', '${plan.numero}');
    if (alEntrar) {
      Voz.decir(nuevo ?? AjustesBurbujas.vozInicio);
    } else {
      Voz.decir(nuevo == null ? numeroNivel : '$numeroNivel $nuevo');
    }
  }

  void _mostrarCartel(String texto, double segundos) {
    _textoCartel = texto;
    _segundosCartel = math.max(0.3, segundos);
    _cartel.duration = Duration(milliseconds: (_segundosCartel * 1000).round());
    _cartel.forward(from: 0);
  }

  // ----------------------------------------- 2. salen y flotan (cada cuadro)

  void _cadaCuadro(Duration tiempo) {
    final t = tiempo.inMicroseconds / 1e6;
    // Si un cuadro tardó mucho, no saltan de golpe.
    final dt = (t - _ahora).clamp(0.0, 0.05);
    _ahora = t;
    _mover(dt);
    _salir();
    _seguirCadena();
    _estallidos.removeWhere((e) => e.terminado(_ahora));
    _animales.removeWhere((a) => a.terminado(_ahora));
    _cuadro.value++;
  }

  double _radioDe(TipoBurbuja tipo, double lado) {
    final tamano = switch (tipo) {
      TipoBurbuja.superBurbuja => AjustesBurbujas.tamanoSuper,
      TipoBurbuja.animalito => AjustesBurbujas.tamanoAnimalito,
      TipoBurbuja.mega => AjustesBurbujas.tamanoMega,
      TipoBurbuja.rapida ||
      TipoBurbuja.chica =>
        AjustesBurbujas.tamanoChica * _entre(0.9, 1.1),
      TipoBurbuja.arcoiris => AjustesBurbujas.tamanoArcoiris,
      TipoBurbuja.normal =>
        _entre(AjustesBurbujas.tamanoMinimo, AjustesBurbujas.tamanoMaximo),
    };
    return tamano * lado / 2;
  }

  /// Cuánto más lento o más rápido que las normales.
  double _rapidezDe(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.superBurbuja => 0.75,
        TipoBurbuja.mega => 0.55,
        TipoBurbuja.animalito => 0.9,
        TipoBurbuja.arcoiris => 0.8,
        TipoBurbuja.rapida => AjustesBurbujas.velocidadRapidas,
        TipoBurbuja.chica => 1.3,
        TipoBurbuja.normal => 1.0,
      };

  int _toquesDe(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.superBurbuja => math.max(2, AjustesBurbujas.toquesSuper),
        TipoBurbuja.mega => math.max(1, AjustesBurbujas.toquesMega),
        _ => 1,
      };

  Color _otroColor() {
    if (_colores.isEmpty) return const Color(0xFF4FC3F7);
    var color = _colores[_azar.nextInt(_colores.length)];
    if (_colores.length > 1 && color == _ultimoColor) {
      color = _colores[(_colores.indexOf(color) + 1) % _colores.length];
    }
    _ultimoColor = color;
    return color;
  }

  /// Sale una burbuja nueva si le toca y hay lugar.
  void _salir() {
    final tam = _tam;
    final plan = _plan;
    if (tam == null || tam.isEmpty || plan == null || _celebrando) return;
    if (_porSalir.isEmpty || _burbujas.length >= math.max(1, plan.aLaVez)) {
      return;
    }
    if (_ahora < _proximaSalida) return;

    final tipo = _porSalir.removeAt(0);
    final lado = tam.shortestSide;
    final radio = _radioDe(tipo, lado);
    final w = tam.width;
    final h = tam.height;

    // Sale por un lado distinto al de la anterior, desde afuera.
    var borde = _azar.nextInt(4);
    if (borde == _ultimoLado) borde = (borde + 1 + _azar.nextInt(3)) % 4;
    _ultimoLado = borde;
    double a(double largo) => _entre(radio, math.max(radio, largo - radio));
    final inicio = switch (borde) {
      0 => Offset(a(w), -radio), // arriba
      1 => Offset(w + radio, a(h)), // derecha
      2 => Offset(a(w), h + radio), // abajo
      _ => Offset(-radio, a(h)), // izquierda
    };
    // Va hacia un punto al azar del medio de la pantalla.
    final destino = Offset(_entre(0.25, 0.75) * w, _entre(0.25, 0.75) * h);
    final rumbo = math.atan2(destino.dy - inicio.dy, destino.dx - inicio.dx);
    final animales = AjustesBurbujas.animalitos;

    _burbujas.add(Burbuja(
      id: _siguienteId++,
      tipo: tipo,
      centro: inicio,
      radio: radio,
      color: _otroColor(),
      velocidad: plan.velocidad * lado * _entre(0.7, 1.3) * _rapidezDe(tipo),
      rumbo: rumbo,
      fase: _azar.nextDouble() * 2 * math.pi,
      toques: _toquesDe(tipo),
      animal: tipo == TipoBurbuja.animalito && animales.isNotEmpty
          ? animales[_azar.nextInt(animales.length)]
          : null,
    )..proximoCambio = _ahora + _entre(0.8, 2.0));
    _proximaSalida = _ahora +
        _entre(AjustesBurbujas.segundosEntreBurbujasMinimo,
            AjustesBurbujas.segundosEntreBurbujasMaximo);
  }

  /// Mueve las burbujas: cada una a su velocidad (que sube y baja un poco),
  /// cambiando de dirección de a poco y rebotando en los bordes.
  void _mover(double dt) {
    final tam = _tam;
    final plan = _plan;
    if (tam == null || plan == null || dt <= 0) return;
    final w = tam.width;
    final h = tam.height;
    final centroZona = Offset(w / 2, h / 2);
    for (final b in _burbujas) {
      b.golpe = math.max(0, b.golpe - dt * 2.2);
      final r = b.radio;
      if (b.adentro) {
        if (_ahora >= b.proximoCambio) {
          final rapida = b.tipo == TipoBurbuja.rapida;
          b.giroBuscado = (_azar.nextDouble() * 2 - 1) *
              1.3 *
              plan.giros *
              (rapida ? 1.6 : 1);
          b.proximoCambio =
              _ahora + _entre(rapida ? 0.5 : 1.0, rapida ? 1.4 : 2.6);
        }
        b.giro += (b.giroBuscado - b.giro) * math.min(1.0, dt * 2);
        b.rumbo += b.giro * dt;
      } else {
        // Mientras entra, si se está alejando, vuelve hacia el medio.
        final hacia = centroZona - b.centro;
        final va = Offset(math.cos(b.rumbo), math.sin(b.rumbo));
        if (hacia.dx * va.dx + hacia.dy * va.dy < 0) {
          b.rumbo = math.atan2(hacia.dy, hacia.dx);
        }
      }
      final v = b.velocidad * (1 + 0.25 * math.sin(_ahora * 0.9 + b.fase));
      b.centro += Offset(math.cos(b.rumbo), math.sin(b.rumbo)) * v * dt;

      final c = b.centro;
      if (!b.adentro) {
        if (c.dx >= r && c.dx <= w - r && c.dy >= r && c.dy <= h - r) {
          b.adentro = true;
        }
        continue;
      }
      // Rebota en los bordes.
      var dx = math.cos(b.rumbo);
      var dy = math.sin(b.rumbo);
      var reboto = false;
      if ((c.dx < r && dx < 0) || (c.dx > w - r && dx > 0)) {
        dx = -dx;
        reboto = true;
      }
      if ((c.dy < r && dy < 0) || (c.dy > h - r && dy > 0)) {
        dy = -dy;
        reboto = true;
      }
      if (reboto) {
        b.rumbo = math.atan2(dy, dx);
        b.giroBuscado = -b.giroBuscado;
        b.giro = -b.giro;
      }
    }
    _chocar();
  }

  /// Dos burbujas que se tocan se empujan y rebotan una con la otra (así no
  /// quedan una encima de la otra).
  void _chocar() {
    for (var i = 0; i < _burbujas.length; i++) {
      final a = _burbujas[i];
      if (!a.adentro) continue;
      for (var j = i + 1; j < _burbujas.length; j++) {
        final b = _burbujas[j];
        if (!b.adentro) continue;
        final entre = a.centro - b.centro;
        final distancia = entre.distance;
        final juntas = (a.radio + b.radio) * 0.95;
        if (distancia >= juntas || distancia == 0) continue;
        // Se separan (la más grande se mueve menos).
        final n = entre / distancia;
        final sobra = juntas - distancia;
        final parteA = b.radio / (a.radio + b.radio);
        a.centro += n * sobra * parteA;
        b.centro -= n * sobra * (1 - parteA);
        // Rebotan (solo si iban una hacia la otra).
        a.rumbo = _reflejar(a.rumbo, n);
        b.rumbo = _reflejar(b.rumbo, -n);
      }
    }
  }

  /// La nueva dirección de una burbuja que choca: si iba contra [n] (la
  /// dirección que la aleja de la otra), rebota.
  double _reflejar(double rumbo, Offset n) {
    final dx = math.cos(rumbo);
    final dy = math.sin(rumbo);
    final contra = dx * n.dx + dy * n.dy;
    if (contra >= 0) return rumbo;
    return math.atan2(dy - 2 * contra * n.dy, dx - 2 * contra * n.dx);
  }

  // --------------------------------------------------- 3. cuando toca

  void _alTocar(PointerDownEvent evento) {
    if (_celebrando || _terminoNivel) return;
    final p = evento.localPosition;
    // La burbuja más cerca del dedo (con un poquito de ayuda alrededor; las
    // chiquitas con más ayuda).
    Burbuja? tocada;
    var mejor = double.infinity;
    for (final b in _burbujas) {
      final limite = b.radio * 1.15 + (b.chiquita ? 18 : 8);
      final cerca = (b.centro - p).distance / limite;
      if (cerca <= 1 && cerca < mejor) {
        mejor = cerca;
        tocada = b;
      }
    }
    if (tocada != null) _tocar(tocada);
  }

  void _tocar(Burbuja b) {
    // Le faltan toques: "boing", se achica un poco.
    if (b.toques > 1) {
      setState(() {
        b.toques--;
        b.golpe = 1;
        b.radio *= b.tipo == TipoBurbuja.mega ? 0.95 : 0.93;
        _estallidos.add(Estallido(
          centro: b.centro,
          radio: b.radio,
          color: b.color,
          inicio: _ahora,
          chico: true,
          conPalabra: false,
        ));
      });
      Sonidos.tocar(AjustesBurbujas.sonidoSuperToque);
      return;
    }
    _reventar(b);
  }

  /// ¡Revienta! [enCadena] = la reventó la arcoíris.
  void _reventar(Burbuja b, {bool enCadena = false}) {
    if (!_burbujas.contains(b)) return;
    final grande = b.tipo == TipoBurbuja.superBurbuja ||
        b.tipo == TipoBurbuja.mega ||
        b.tipo == TipoBurbuja.arcoiris;

    // El sonido.
    if (grande) {
      Sonidos.tocar(AjustesBurbujas.sonidoSuperPop);
    } else {
      final sonidos = AjustesBurbujas.sonidosPop;
      if (sonidos.isNotEmpty) {
        Sonidos.tocar(sonidos[_turnoPop++ % sonidos.length]);
      }
    }
    if (b.tipo == TipoBurbuja.animalito) {
      Sonidos.tocar(AjustesBurbujas.sonidoAnimalito);
    }

    setState(() {
      _burbujas.remove(b);
      _estallidos.add(Estallido(
        centro: b.centro,
        radio: b.radio,
        color: b.color,
        inicio: _ahora,
        grande: grande,
        arcoiris: b.tipo == TipoBurbuja.arcoiris,
        conPalabra: AjustesBurbujas.mostrarPop && !enCadena,
      ));
      _reventadas++;
      _estrellas++;

      switch (b.tipo) {
        case TipoBurbuja.mega:
          final hijas = _soltarHijas(b);
          // Si la reventó la arcoíris, sus burbujitas también revientan.
          if (enCadena) {
            for (var k = 0; k < hijas.length; k++) {
              _cadena.add((_ahora + 0.2 + k * 0.08, hijas[k]));
            }
          }
        case TipoBurbuja.animalito:
          if (b.animal != null) {
            _animales.add(AnimalLibre(b.animal!, b.centro, b.radio, _ahora));
          }
        case TipoBurbuja.arcoiris:
          // ¡Revientan todas las demás, una tras otra, desde la más cerca!
          final otras = <Burbuja>[..._burbujas]..sort((x, y) =>
              (x.centro - b.centro)
                  .distance
                  .compareTo((y.centro - b.centro).distance));
          for (var k = 0; k < otras.length; k++) {
            _cadena.add((_ahora + 0.15 + k * 0.1, otras[k]));
          }
        default:
          break;
      }

      // Si no queda ninguna en la pantalla, la siguiente sale enseguida.
      if (_burbujas.isEmpty) {
        _proximaSalida = math.min(_proximaSalida, _ahora + 0.3);
      }
    });
    _revisarFin();
  }

  /// La mega burbuja se rompe en burbujitas que salen para todos lados.
  List<Burbuja> _soltarHijas(Burbuja mega) {
    final tam = _tam;
    final plan = _plan;
    if (tam == null || plan == null) return const <Burbuja>[];
    final lado = tam.shortestSide;
    final n = math.max(0, AjustesBurbujas.hijasMega);
    final hijas = <Burbuja>[];
    for (var i = 0; i < n; i++) {
      final angulo = i * 2 * math.pi / n + _entre(-0.3, 0.3);
      final direccion = Offset(math.cos(angulo), math.sin(angulo));
      final radio = _radioDe(TipoBurbuja.chica, lado);
      var centro = mega.centro + direccion * mega.radio * 0.35;
      // Que no queden afuera de la pantalla.
      centro = Offset(
        centro.dx.clamp(radio, math.max(radio, tam.width - radio)),
        centro.dy.clamp(radio, math.max(radio, tam.height - radio)),
      );
      hijas.add(Burbuja(
        id: _siguienteId++,
        tipo: TipoBurbuja.chica,
        centro: centro,
        radio: radio,
        color: _otroColor(),
        velocidad: plan.velocidad * lado * _rapidezDe(TipoBurbuja.chica),
        rumbo: angulo,
        fase: _azar.nextDouble() * 2 * math.pi,
        nace: _ahora,
      )
        ..adentro = true
        ..proximoCambio = _ahora + _entre(0.8, 2.0));
    }
    _burbujas.addAll(hijas);
    return hijas;
  }

  /// Las que revientan solas después de la arcoíris.
  void _seguirCadena() {
    if (_cadena.isEmpty) return;
    final listas = _cadena.where((c) => c.$1 <= _ahora).toList();
    if (listas.isEmpty) return;
    _cadena.removeWhere((c) => c.$1 <= _ahora);
    for (final (_, b) in listas) {
      _reventar(b, enCadena: true);
    }
    _revisarFin();
  }

  void _revisarFin() {
    if (_terminoNivel ||
        _burbujas.isNotEmpty ||
        _porSalir.isNotEmpty ||
        _cadena.isNotEmpty) {
      return;
    }
    _terminoNivel = true;
    // Ya queda guardado que el próximo es el siguiente.
    ProgresoBurbujas.guardar(_numeroNivel + 1);
    // Se deja ver la última explosión antes del festejo.
    Future<void>.delayed(const Duration(milliseconds: 450), _festejar);
  }

  void _festejar() {
    if (!mounted) return;
    final cada = AjustesBurbujas.celebracionGrandeCada;
    if (cada > 0 && _numeroNivel % cada == 0) {
      // La celebración grande.
      setState(() => _celebrando = true);
      Sonidos.felicidades();
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _celebrando) Voz.decir(AjustesBurbujas.vozCelebracion);
      });
      return;
    }
    // El festejo corto: fuegos artificiales de burbujas y "¡MUY BIEN!".
    final tam = _tam;
    if (tam != null) {
      for (var k = 0; k < 5; k++) {
        _estallidos.add(Estallido(
          centro: Offset(
              _entre(0.15, 0.85) * tam.width, _entre(0.15, 0.7) * tam.height),
          radio: tam.shortestSide * _entre(0.08, 0.13),
          color: _otroColor(),
          inicio: _ahora + k * 0.2,
          grande: true,
          arcoiris: k.isOdd,
          conPalabra: false,
        ));
      }
    }
    Sonidos.acierto();
    final frases = AjustesBurbujas.vozMuyBien;
    if (frases.isNotEmpty) Voz.decir(frases[_azar.nextInt(frases.length)]);
    _mostrarCartel(
        AjustesBurbujas.festejoCorto, AjustesBurbujas.segundosFestejoCorto);
    final nivel = _numeroNivel;
    Future<void>.delayed(
        Duration(
            milliseconds:
                (AjustesBurbujas.segundosFestejoCorto * 1000).round()), () {
      if (mounted && _numeroNivel == nivel && _terminoNivel) {
        _empezarNivel(nivel + 1);
      }
    });
  }

  void _terminoCelebracion() {
    if (!mounted) return;
    setState(() => _celebrando = false);
    _empezarNivel(_numeroNivel + 1);
  }

  // ------------------------------------------------------ 4. cómo se ve

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // El cielo, con nubes (no cambia: se dibuja una sola vez).
          const Positioned.fill(
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFF81D4FA), Color(0xFFE1F5FE)],
                  ),
                ),
                child: CustomPaint(painter: _PintorNubes()),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                BarraJuego(estrellas: _estrellas, alRepetir: _decirQueHacer),
                _progreso(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, caja) {
                      _tam = caja.biggest;
                      return _zonaDeJuego(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_celebrando)
            Positioned.fill(
              child: Celebracion(
                linea1: AjustesBurbujas.celebracionLinea1,
                linea2: AjustesBurbujas.celebracionLinea2,
                segundos: AjustesBurbujas.segundosCelebracionGrande,
                alTerminar: _terminoCelebracion,
              ),
            ),
        ],
      ),
    );
  }

  /// Cuántas lleva y cuántas faltan: una burbujita por cada burbuja del
  /// nivel (las que ya reventó son estrellas). Si son muchas, una barra.
  Widget _progreso() {
    final total = _total;
    final Widget contenido;
    if (total <= 24) {
      contenido = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: i < _reventadas
                    ? const Icon(Icons.star_rounded,
                        key: ValueKey<String>('hecha'),
                        size: 28,
                        color: Color(0xFFFFC107))
                    : Container(
                        key: const ValueKey<String>('falta'),
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.6),
                          border: Border.all(
                              color: const Color(0xFF4FC3F7), width: 2.5),
                        ),
                      ),
              ),
          ],
        ),
      );
    } else {
      final parte = total == 0 ? 0.0 : _reventadas / total;
      contenido = Row(
        children: [
          const Icon(Icons.star_rounded, size: 28, color: Color(0xFFFFC107)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                key: const ValueKey<String>('barra'),
                value: parte,
                minHeight: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                color: const Color(0xFFFFC107),
              ),
            ),
          ),
        ],
      );
    }
    return Padding(
      key: const ValueKey<String>('progreso'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SizedBox(height: 30, child: contenido),
    );
  }

  Widget _zonaDeJuego(BuildContext context) {
    final letra = DefaultTextStyle.of(context).style;
    return Listener(
      key: const ValueKey<String>('zona'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: _alTocar,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PintorJuego(this, letra),
                ),
              ),
            ),
            // El cartel grande ("NIVEL 3", "¡MUY BIEN!").
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _cartel,
                  builder: (context, _) {
                    if (!_cartel.isAnimating || _celebrando) {
                      return const SizedBox.shrink();
                    }
                    final s = _cartel.value * _segundosCartel;
                    final crece = Curves.easeOutBack
                        .transform((s / 0.25).clamp(0.0, 1.0));
                    final queda = _segundosCartel - s;
                    final opacidad = (queda / 0.25).clamp(0.0, 1.0);
                    return Center(
                      child: Opacity(
                        opacity: opacidad,
                        child: Transform.scale(
                          scale: 0.3 + 0.7 * crece,
                          child: TituloColores(
                            _textoCartel,
                            key: const ValueKey<String>('cartel'),
                            tamano: 64,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibuja todo lo que se mueve (burbujas, explosiones y animalitos) en un
/// solo dibujo, que se repinta en cada cuadro.
class _PintorJuego extends CustomPainter {
  _PintorJuego(this.juego, this.letra) : super(repaint: juego._cuadro);

  final EstadoBurbujasJuego juego;
  final TextStyle letra;

  @override
  void paint(Canvas canvas, Size tam) {
    final ahora = juego._ahora;
    for (final b in juego._burbujas) {
      pintarBurbuja(canvas, b, ahora, letra: letra);
    }
    pintarEstallidos(canvas, juego._estallidos, ahora, letra: letra);
    pintarAnimales(canvas, juego._animales, ahora, letra: letra);
  }

  @override
  bool shouldRepaint(covariant _PintorJuego viejo) =>
      viejo.juego != juego || viejo.letra != letra;
}

/// Unas nubes blancas suavecitas en el cielo.
class _PintorNubes extends CustomPainter {
  const _PintorNubes();

  @override
  void paint(Canvas canvas, Size tam) {
    final pintura = Paint()..color = Colors.white.withValues(alpha: 0.55);
    void nube(double x, double y, double s) {
      final c = Offset(tam.width * x, tam.height * y);
      final r = tam.shortestSide * s;
      canvas.drawCircle(c, r, pintura);
      canvas.drawCircle(c + Offset(-r * 0.9, r * 0.3), r * 0.7, pintura);
      canvas.drawCircle(c + Offset(r * 0.95, r * 0.25), r * 0.75, pintura);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(c.dx - r * 1.5, c.dy, c.dx + r * 1.6, c.dy + r * 0.85),
          Radius.circular(r * 0.45),
        ),
        pintura,
      );
    }

    nube(0.2, 0.2, 0.07);
    nube(0.78, 0.38, 0.09);
    nube(0.3, 0.7, 0.08);
    nube(0.85, 0.85, 0.06);
  }

  @override
  bool shouldRepaint(covariant _PintorNubes viejo) => false;
}
