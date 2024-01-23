import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Snake',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MySnake(),
    );
  }
}

class MySnake extends StatefulWidget {
  const MySnake({super.key});

  @override
  State<MySnake> createState() => _MySnakeState();
}

class XY {
  late int x, y;
  XY(this.x, this.y);
}

class _MySnakeState extends State<MySnake> {
  late List<List<int>> data;

  List<int> dx = [0, 1, 0, -1], dy = [-1, 0, 1, 0];
  int d = 0;
  final int width = 20, height = 12, siz = 20;
  final int fps = 5;
  int length = 4;
  double distPerFrame = 0.25;
  bool isPlaying = false, islose = false, calledMove = false;

  FocusNode focusNode = FocusNode();
  Random random = Random();
  late Timer timer;

  void lose() {
    isPlaying = false;
    islose = true;
    timer.cancel();
    print("losed");
  }

  void makeFood() {
    int x = random.nextInt(width), y = random.nextInt(height);
    print("${x} ${y}");
    if (data[y][x] > 0) {
      makeFood();
    } else {
      data[y][x] = -1;
    }
  }

  void move() {
    setState(() {
      late int headx, heady;
      List<XY> snake = List.empty(growable: true);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (data[y][x] > 0) snake.add(XY(x, y));
          if (data[y][x] == length) {
            headx = x;
            heady = y;
          }
        }
      }
      // print(data);
      int xx = headx + dx[d], yy = heady + dy[d];
      if (xx < 0 || xx >= width || yy < 0 || yy >= height || data[yy][xx] > 0) {
        lose();
        return;
      }
      if (data[yy][xx] == 0) {
        for (var xy in snake) {
          data[xy.y][xy.x]--;
        }
      } else {
        length += 1;
        makeFood();
      }
      data[yy][xx] = length;
      calledMove = true;
    });
  }

  void newGame() {
    d = 0;
    length = height ~/ 3;
    focusNode.requestFocus();
    data = List.generate(height, (y) => List.generate(width, (x) => 0));
    int beginy = (height / 2 - length / 2).round(), x = (width / 2).round();
    print("beginy, x, length: ${beginy} ${x} ${length}");
    for (int i = 0; i < length; i++) {
      data[beginy + i][x] = length - i;
    }
  }

  @override
  void initState() {
    super.initState();
    newGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: focusNode,
        onKey: (event) {
          setState(() {
            print("Pressed ${event.data.keyLabel}");
            if (!isPlaying || islose || !calledMove) return;
            int newd = -1;
            switch (event.data.keyLabel.toLowerCase()) {
              case 'w':
                newd = 0;
                break;
              case 'd':
                newd = 1;
                break;
              case 's':
                newd = 2;
                break;
              case 'a':
                newd = 3;
                break;
              default:
                return;
            }
            if (d == 0 && newd == 2 ||
                d == 2 && newd == 0 ||
                d == 1 && newd == 3 ||
                d == 3 && newd == 1) return;
            calledMove = false;
            d = newd;
          });
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                painter: SnakePainter(data, height, width, siz, length),
                child: Container(
                  width: width * siz.toDouble(),
                  height: height * siz.toDouble(),
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.black)),
                ),
              ),
              SizedBox(height: 100),
              Offstage(
                offstage: isPlaying,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (islose) {
                        islose = false;
                        newGame();
                      } else {
                        isPlaying = true;
                        timer = Timer.periodic(
                            Duration(milliseconds: 1000 ~/ fps), (timer) {
                          move();
                        });
                        newGame();
                        makeFood();
                      }
                    });
                  },
                  child: Text(islose ? "Restart" : "Play"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SnakePainter extends CustomPainter {
  List<List<int>> data;
  late int height, width, siz, length;

  SnakePainter(this.data, this.height, this.width, this.siz, this.length);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        paint.color = data[y][x] > 0 ? Colors.purple.shade200 : Colors.white;
        if (data[y][x] == -1) paint.color = Colors.orange;
        if (data[y][x] == length) paint.color = Colors.deepPurple;
        canvas.drawRect(
            Rect.fromLTWH(x * siz.toDouble(), y * siz.toDouble(),
                siz.toDouble(), siz.toDouble()),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
