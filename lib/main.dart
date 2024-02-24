import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SnakeGameApp());

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SnakeGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SnakeGame extends StatefulWidget {
  const SnakeGame({Key? key}) : super(key: key);

  @override
  _SnakeGameState createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const gridSize = 20;
  List<int> snake = [45, 44];
  int food = 0;
  var direction = 'right';
  late Timer gameTimer;

  final List<int> wall = [
    for (int i = 0; i < gridSize; i++) i, // Top wall
    for (int i = gridSize; i < gridSize * (gridSize - 1); i += gridSize) i, // Left wall
    for (int i = gridSize * 2 - 1; i < gridSize * gridSize; i += gridSize) i, // Right wall
    for (int i = gridSize * (gridSize - 1); i < gridSize * gridSize; i++) i, // Bottom wall
  ];

  bool hasEaten = false; // Indicates whether the snake has eaten the fruit.
  int score = 0; // Variable to keep track of the score.
  List<int> snakePath = [];
  int highScore = 0; // Variable to store the high score.

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadGame();
    loadHighScore();
  }

  void loadGame() {
    Timer(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });
      startGame();
    });
  }

  void startGame() {
    const start = 45;
    setState(() {
      snake = [start];
      direction = 'right';
      generateFood();
      hasEaten = false;
      score = 0; // Reset the score when starting a new game.
      snakePath = List.filled(gridSize * gridSize, 0);
      snakePath[start] = 1;
    });
    gameTimer = Timer.periodic(const Duration(milliseconds: 300), (Timer timer) {
      moveSnake();
      checkGameStatus();
    });
  }

  void generateFood() {
    setState(() {
      do {
        food = DateTime.now().millisecondsSinceEpoch % (gridSize * gridSize);
      } while (snake.contains(food) || wall.contains(food));
    });
  }

  void moveSnake() {
    int head = snake.first;
    int newHead = 0;

    if (direction == 'right') {
      newHead = head + 1;
    } else if (direction == 'left') {
      newHead = head - 1;
    } else if (direction == 'up') {
      newHead = head - gridSize;
    } else if (direction == 'down') {
      newHead = head + gridSize;
    }

    // Check for collisions with walls and change direction accordingly
    if (wall.contains(newHead)) {
      if (newHead % gridSize == 0) {
        direction = 'right';
      } else if (newHead % gridSize == gridSize - 1) {
        direction = 'left';
      } else if (newHead < gridSize) {
        direction = 'down';
      } else {
        direction = 'up';
      }
    }

    setState(() {
      if (newHead == food) {
        snake.insert(0, newHead);
        generateFood();
        hasEaten = true;
        score++; // Increment the score when the snake eats the fruit.
      } else {
        // Move the snake by adding the new head and removing the tail.
        snake.insert(0, newHead);
        if (!hasEaten) {
          // If the snake has not eaten, remove the tail to keep the size constant.
          snake.removeLast();
        }
        hasEaten = false;
      }

      snakePath = List.filled(gridSize * gridSize, 0);
      snake.forEach((pos) {
        snakePath[pos] = 1;
      });

      if (score > highScore) {
        // Check if a new high score is achieved
        highScore = score;
        updateHighScore(highScore);
        showHighScoreAchievedDialog();
      }
    });
  }

  void checkGameStatus() {
    int head = snake.first;
    if (head < 0 ||
        head >= gridSize * gridSize ||
        snake.sublist(1).contains(head) ||
        wall.contains(head)) {
      // Game over
      gameTimer.cancel();
      showGameOverDialog();
    }
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> updateHighScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', newScore);
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Game Over"),
          content: Text("Score: $score\nHigh Score: $highScore"),
          actions: <Widget>[
            TextButton(
              child: Text("Restart"),
              onPressed: () {
                Navigator.of(context).pop();
                startGame(); // Restart the game.
              },
            ),
          ],
        );
      },
    );
  }

  void showHighScoreAchievedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("New High Score Achieved!"),
          content: Text("Congratulations! You've achieved a new high score."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildLoadingScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          "Nexygen Games...",
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(height: 10),
        CircularProgressIndicator(
          value: null,
          strokeWidth: 5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      ],
    );
  }

  Row buildDirectionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          onPressed: () {
            if (direction != 'down') {
              direction = 'up';
            }
          },
          child: Icon(Icons.arrow_drop_up),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(20),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                if (direction != 'left') {
                  direction = 'right';
                }
              },
              child: Icon(Icons.arrow_right),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (direction != 'up') {
                  direction = 'down';
                }
              },
              child: Icon(Icons.arrow_drop_down),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            if (direction != 'right') {
              direction = 'left';
            }
          },
          child: Icon(Icons.arrow_left),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Snake Game'),
        ),
        body: Center(
          child: buildLoadingScreen(),
        ),
      );
    }

    List<Widget> gridChildren = [];
    for (int i = 0; i < gridSize * gridSize; i++) {
      if (snakePath[i] == 1) {
        gridChildren.add(
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
        );
      } else if (food == i) {
        gridChildren.add(
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
        );
      } else if (wall.contains(i)) {
        gridChildren.add(
          Container(
            decoration: BoxDecoration(
              color: Colors.brown,
            ),
          ),
        );
      } else {
        gridChildren.add(
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Snake Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: GridView.count(
                crossAxisCount: gridSize,
                children: gridChildren,
              ),
            ),
            buildDirectionButtons(),
            ElevatedButton(
              onPressed: () {
                startGame();
              },
              child: Text('Restart'),
            ),
            Text(
              'Score: $score',
              style: TextStyle(fontSize: 24),
            ),
            Text(
              'High Score: $highScore',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
