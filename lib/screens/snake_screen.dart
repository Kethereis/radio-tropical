import 'dart:math';
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

  Direction direction = Direction.right;

  late Ticker _ticker;
  Duration lastTime = Duration.zero;

  List<Offset> snake = [];
  double snakeLength = cellSize;
  late Offset head;

  late Offset food;
  final random = Random();

  int score = 0;
  int bestScore = 0;

  late int rows;
  late int columns;

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
    food = Offset(
      random.nextInt(columns) * cellSize + cellSize / 2,
      random.nextInt(rows) * cellSize + cellSize / 2,
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
    }

    for (int i = (cellSize ~/ 2); i < snake.length; i++) {
      if ((head - snake[i]).distance < cellSize / 2) {
        bestScore = max(bestScore, score);
        resetGame();
        return;
      }
    }

    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // calcula dinamicamente colunas e linhas
    columns = ((size.width - 5)/ cellSize).floor();
    rows = ((size.height - 95) / cellSize).floor(); // reserva espaço pro placar

    if (snake.isEmpty) {
      resetGame();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea( // 👈 evita que o placar fique colado na barra de status
        child: Column(
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
              child: GestureDetector(
                onHorizontalDragEnd: _handleSwipe,
                onVerticalDragEnd: _handleSwipe,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 4),
                  ),
                  child: CustomPaint(
                    painter:
                    SnakePainter(snake, food, rows, columns, cellSize),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SnakePainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final int rows;
  final int columns;
  final double cellSize;

  SnakePainter(this.snake, this.food, this.rows, this.columns, this.cellSize);

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
