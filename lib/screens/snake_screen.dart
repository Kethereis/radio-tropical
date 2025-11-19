import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

enum Direction { up, down, left, right }

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame>
    with SingleTickerProviderStateMixin {
  static const double cellSize = 20.0; // mantém tamanho de cada célula
  final double speed = 100;
  final ValueNotifier<int> repaintNotifier = ValueNotifier(0);
  final double boardPadding = 5;

  Direction direction = Direction.right;

  late Ticker _ticker;
  Duration lastTime = Duration.zero;

  List<Offset> snake = [];
  double snakeLength = cellSize;
  Offset head = Offset.zero;

  late Offset food;
  final random = Random();

  int score = 0;
  int bestScore = 0;

  int rows = 0;
  int columns = 0;

  ui.Image? backgroundImage;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    _ticker.dispose();
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey.keyLabel.toLowerCase()) {
        case 'w':
        case 'arrow up':
          if (direction != Direction.down) direction = Direction.up;
          break;
        case 's':
        case 'arrow down':
          if (direction != Direction.up) direction = Direction.down;
          break;
        case 'a':
        case 'arrow left':
          if (direction != Direction.right) direction = Direction.left;
          break;
        case 'd':
        case 'arrow right':
          if (direction != Direction.left) direction = Direction.right;
          break;
      }
    }
    return false;
  }

  void resetGame() {
    head = Offset((columns ~/ 2) * cellSize, (rows ~/ 2) * cellSize);
    snake = [head];
    snakeLength = cellSize;
    score = 0;
    spawnFood();
  }

  void spawnFood() {
    // se ainda não sabemos o tamanho, não sorteia
    if (columns <= 0 || rows <= 0) return;

    final foodColumn = random.nextInt(columns); // agora columns >= 1
    final foodRow    = random.nextInt(rows);    // idem

    food = Offset(
      foodColumn * cellSize + cellSize / 2,
      foodRow * cellSize   + cellSize / 2,
    );
  }

  void _onTick(Duration elapsed) {

    final dt = (elapsed - lastTime).inMilliseconds / 1000;
    lastTime = elapsed;

    if (dt > 0.05) return;

    Offset dirVec;
    switch (direction) {
      case Direction.up:
        dirVec = const Offset(0, -1);
        break;
      case Direction.down:
        dirVec = const Offset(0, 1);
        break;
      case Direction.left:
        dirVec = const Offset(-1, 0);
        break;
      case Direction.right:
        dirVec = const Offset(1, 0);
        break;
    }
    head += dirVec * speed * dt;

    if (head.dx < 0 ||
        head.dy < 0 ||
        head.dx > columns * cellSize ||
        head.dy > rows * cellSize) {
      bestScore = max(bestScore, score);
      resetGame();
      return;
    }

    snake.insert(0, head);

    double total = 0;
    for (int i = 0; i < snake.length - 1; i++) {
      total += (snake[i] - snake[i + 1]).distance;
      if (total > snakeLength) {
        snake = snake.sublist(0, i + 1);
        break;
      }
    }

    if ((head - food).distance < cellSize / 2) {
      snakeLength += 50;
      score++;
      spawnFood();
      setState(() {});
    }

    for (int i = (cellSize ~/ 2); i < snake.length; i++) {
      if ((head - snake[i]).distance < cellSize / 2) {
        bestScore = max(bestScore, score);
        resetGame();
        return;
      }
    }

    repaintNotifier.value++;
    setState(() {

    });
  }
  void _handleSwipe(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dx.abs() >
        details.velocity.pixelsPerSecond.dy.abs()) {
      if (details.velocity.pixelsPerSecond.dx > 0 &&
          direction != Direction.left) {
        direction = Direction.right;
      } else if (details.velocity.pixelsPerSecond.dx < 0 &&
          direction != Direction.right) {
        direction = Direction.left;
      }
    } else {
      if (details.velocity.pixelsPerSecond.dy > 0 &&
          direction != Direction.up) {
        direction = Direction.down;
      } else if (details.velocity.pixelsPerSecond.dy < 0 &&
          direction != Direction.down) {
        direction = Direction.up;
      }
    }
  }
  bool _initialized = false;

  void _initBackground() {
    if (_initialized || rows <= 0 || columns <= 0) return;
    _initialized = true;

    SnakePainter.generateBackground(rows, columns, cellSize).then((img) {
      if (mounted) {
        setState(() => backgroundImage = img);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _initBackground();


    // if (snake.isEmpty) {
    //   resetGame();
    // }

    if (backgroundImage == null && rows > 0 && columns > 0) {
      SnakePainter.generateBackground(rows, columns, cellSize).then((img) {
        if (mounted) {
          //(context.findRenderObject() as RenderCustomPaint?)?.markNeedsPaint();
        }
      });
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea( // 👈 evita que o placar fique colado na barra de status
        child:  Padding(
          // ajuste esse valor (ex.: 72~92) pra altura real do seu player
          padding: const EdgeInsets.only(bottom: 88),
          child:Column(
          children: [
            // placar
            Container(
              color: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.apple, color: Colors.red),
                    const SizedBox(width: 4),
                    Text("$score",
                        style:
                        const TextStyle(color: Colors.white, fontSize: 18)),
                  ]),
                  Row(children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text("$bestScore",
                        style:
                        const TextStyle(color: Colors.white, fontSize: 18)),
                  ]),
                ],
              ),
            ),
            // jogo ocupando tela inteira
            Expanded(
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardW = constraints.maxWidth - 0.1  * boardPadding;
                    final boardH = constraints.maxHeight - 0.1 * boardPadding;

                    // deixa o campo QUADRADO e centralizado
                    final side = min(boardW, boardH);
                    final visibleColumns = max(1, (side / cellSize).floor());
                    final visibleRows    = max(1, (side / cellSize).floor());

                    columns = visibleColumns;
                    rows    = visibleRows;

                    _initBackground();

                    // inicializa o jogo só depois de rows/columns prontos
                    if (snake.isEmpty) resetGame();

                    return GestureDetector(
                onHorizontalDragEnd: _handleSwipe,
                onVerticalDragEnd: _handleSwipe,
                child: Center( // centraliza o campo
                  child: Container(
                    padding: EdgeInsets.all(boardPadding),
                    width: side,
                    height: side,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(side, side), // garante tamanho exato do canvas
                      painter: SnakePainter(
                          snake, food, rows, columns, cellSize, backgroundImage, repaintNotifier
                      ),
                    ),
                  ),
                ),
              ));}),
            ),
          ],
        ),
      ),
    ));
  }
}

class SnakePainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final int rows;
  final int columns;
  final double cellSize;
  final ui.Image? cachedBackground;

  SnakePainter(this.snake, this.food, this.rows, this.columns, this.cellSize, this.cachedBackground,
      ValueNotifier<int> repaintNotifier,
      ): super(repaint: repaintNotifier);
  static Future<ui.Image> generateBackground(
      int rows, int columns, double cellSize
      ) async {
    // garante mínimo de 1x1 px
    final w = max(1, (columns * cellSize).toInt());
    final h = max(1, (rows    * cellSize).toInt());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        final paint = Paint()
          ..color = (x + y) % 2 == 0
              ? const Color(0xFFB3E5FC)
              : const Color(0xFFE1F5FE);
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(w, h);
  }
  TextPainter? _foodPainter;
  RadialGradient? _shader1;
  @override
  void paint(Canvas canvas, Size size) {
    // tabuleiro
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        final paint = Paint()
          ..color =
          (x + y) % 2 == 0 ? Colors.blueAccent : Colors.white;
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }

    // corpo da cobra
    final path = Path()..moveTo(snake.first.dx, snake.first.dy);
    for (final p in snake) {
      path.lineTo(p.dx, p.dy);
    }

    final bodyPaint = Paint()
      ..color = Colors.green // 👈 cobra verde
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, bodyPaint);

    // olhos da cobra
    if (snake.isNotEmpty) {
      final head = snake.first;
      final eyePaint = Paint()..color = Colors.white;
      final pupilPaint = Paint()..color = Colors.black;

      canvas.drawCircle(head.translate(-6, -6), 4, eyePaint);
      canvas.drawCircle(head.translate(6, -6), 4, eyePaint);
      canvas.drawCircle(head.translate(-6, -6), 2, pupilPaint);
      canvas.drawCircle(head.translate(6, -6), 2, pupilPaint);
    }

    // comida
    final foodPaint = Paint()..color = Colors.red;
    canvas.drawCircle(food, cellSize * 0.35, foodPaint);
    final leafPaint = Paint()..color = Colors.green;
    canvas.drawCircle(food.translate(0, -10), 4, leafPaint);
  }

  @override
  bool shouldRepaint(covariant SnakePainter oldDelegate) => true;
}
