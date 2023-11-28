import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game',
      home: SnakeGame(),
    );
  }
}

class SnakeGame extends StatefulWidget {
  @override
  _SnakeGameState createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int gridSize = 20;
  static const double cellSize = 20.0;
  static const int bonusFoodScore = 5;

  List<Offset> snake = [Offset(5, 5)];
  Offset food = Offset(10, 10);
  Offset bonusFood = Offset(-1, -1); // Initial position outside the grid
  Direction direction = Direction.right;
  bool isPlaying = false;
  int score = 0;
  int snakeSpeed = 200; // Initial snake speed in milliseconds

  void startGame() {
    setState(() {
      snake = [Offset(5, 5)];
      generateFood();
      direction = Direction.right;
      isPlaying = true;
      score = 0;
      snakeSpeed = 300;
    });

    // Start the bonus food timer
    Timer(Duration(seconds: 10), () {
      setState(() {
        bonusFood = Offset(-1, -1); // Reset bonus food position
      });
    });

    // Periodically check for bonus food appearance
    Timer.periodic(Duration(seconds: 30), (timer) {
      generateBonusFood();
    });
  }

  void generateFood() {
    food = Offset(
      Random().nextInt(gridSize - 1).toDouble(),
      Random().nextInt(gridSize - 1).toDouble(),
    );
  }

  void generateBonusFood() {
    if (Random().nextInt(10) < 2) {
      setState(() {
        bonusFood = Offset(
          Random().nextInt(gridSize - 1).toDouble(),
          Random().nextInt(gridSize - 1).toDouble(),
        );
      });

      // Schedule bonus food disappearance after 10 seconds
      Timer(Duration(seconds: 10), () {
        setState(() {
          bonusFood = Offset(-1, -1); // Reset bonus food position
        });
      });
    }
  }

  void moveSnake() {
    Offset head = snake.first;

    switch (direction) {
      case Direction.up:
        head = Offset(head.dx, (head.dy - 1) % gridSize);
        break;
      case Direction.down:
        head = Offset(head.dx, (head.dy + 1) % gridSize);
        break;
      case Direction.left:
        head = Offset((head.dx - 1) % gridSize, head.dy);
        break;
      case Direction.right:
        head = Offset((head.dx + 1) % gridSize, head.dy);
        break;
    }

    if (snake.contains(head) || head.dx < 0 || head.dy < 0 || head.dx >= gridSize || head.dy >= gridSize) {
      gameOver();
      return;
    }

    setState(() {
      if (head == food) {
        snake.insert(0, head);
        generateFood();
        score++;
        increaseSnakeSpeed();
      } else if (head == bonusFood) {
        snake.insert(0, head);
        bonusFood = Offset(-1, -1); // Reset bonus food position
        score += bonusFoodScore;
        increaseSnakeSpeed();
      } else {
        snake.insert(0, head);
        snake.removeLast();
      }
    });
  }

  void increaseSnakeSpeed() {
    if (score % 5 == 0 && snakeSpeed > 50) {
      // Increase speed every 5 points, with a minimum speed of 50 milliseconds
      setState(() {
        snakeSpeed -= 10;
      });
    }
  }

  void gameOver() {
    setState(() {
      isPlaying = false;
      bonusFood = Offset(-1, -1); // Reset bonus food position
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Container(
            height: 60,
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Your Score: $score'),
                SizedBox(height: 10),
                Text('You hit  yourself!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
              child: Text('Restart'),
            ),
          ],
          contentPadding: EdgeInsets.all(0),
        );
      },
    );
  }

  void handleDirection(Direction newDirection) {
    if ((direction == Direction.up && newDirection != Direction.down) ||
        (direction == Direction.down && newDirection != Direction.up) ||
        (direction == Direction.left && newDirection != Direction.right) ||
        (direction == Direction.right && newDirection != Direction.left)) {
      direction = newDirection;
    }
  }

  @override
  void initState() {
    super.initState();
    startGame();
    Timer.periodic(Duration(milliseconds: snakeSpeed), (timer) {
      if (isPlaying) {
        moveSnake();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snake Game'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Score: $score', style: TextStyle(fontSize: 18)),
            ],
          ),
          Expanded(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 0) {
                  handleDirection(Direction.down);
                } else if (details.primaryDelta! < 0) {
                  handleDirection(Direction.up);
                }
              },
              onHorizontalDragUpdate: (details) {
                if (details.primaryDelta! > 0) {
                  handleDirection(Direction.right);
                } else if (details.primaryDelta! < 0) {
                  handleDirection(Direction.left);
                }
              },
              child: Container(
                color: Colors.black,
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                  ),
                  itemCount: gridSize * gridSize,
                  itemBuilder: (context, index) {
                    int row = index ~/ gridSize;
                    int col = index % gridSize;

                    Offset position = Offset(col.toDouble(), row.toDouble());

                    if (snake.contains(position)) {
                      return SnakeCell();
                    } else if (position == food) {
                      return FoodCell();
                    } else if (position == bonusFood) {
                      return BonusFoodCell();
                    } else {
                      return EmptyCell();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum Direction { up, down, left, right }

class SnakeCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}

class FoodCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}

class BonusFoodCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow,
        shape: BoxShape.circle,
      ),
    );
  }
}

class EmptyCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
