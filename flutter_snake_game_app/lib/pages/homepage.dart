import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_snake_game_app/utils/blank_pixels.dart';
import 'package:flutter_snake_game_app/utils/food_pixel.dart';
import 'package:flutter_snake_game_app/utils/highscores.dart';
import 'package:flutter_snake_game_app/utils/snake_pixel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum snakeDirections { UP, DOWN, RIGHT, LEFT }

class _HomePageState extends State<HomePage> {
  int rowsize = 10;
  int totalNoOfGrids = 100;
  //snake position
  List<int> snakePositions = [0];
  //food position
  int foodPosition = 23;

  //current score
  int currentScore = 0;

  //game started
  bool gameStarted = false;
  Icon icon = Icon(Icons.play_arrow);

  //name controller
  final _nameController = TextEditingController();

  //highest scores list
  List<String> highScoreDocId = [];
  late final Future? letsgetDocId;

  @override
  void initState() {
    letsgetDocId = getDocId();
    super.initState();
  }

  Future getDocId() async {
    await FirebaseFirestore.instance
        .collection("highscores")
        .orderBy("score", descending: true)
        .limit(10)
        .get()
        .then((value) {
      value.docs.forEach((element) {
        highScoreDocId.add(element.reference.id);
      });
    });
  }

  //start the game button
  void startGame() {
    gameStarted = true;
    icon = Icon(Icons.pause);
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      //for every 200ms the snake should move forward
      setState(() {
        //keep the snake moving
        snakeDirection();
        //check if its game over or not
        if (endGame()) {
          timer.cancel();
          //and display a dialouge box to show the score and say its is game over
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: Colors.grey[700],
                  title: const Text(
                    "Game Over",
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    children: [
                      Text("your score is:" + currentScore.toString()),
                      const SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: "Enter your name....",
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(7))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(7))),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          submitScore();
                          newGame();
                        },
                        child: const Text(
                          "Submit",
                          style: TextStyle(color: Colors.pink),
                        )),
                  ],
                );
              });
        }
      });
    });
  }

  void submitScore() {
    //get access to the firestore
    var database = FirebaseFirestore.instance;

    //add the name and score to the database
    database
        .collection("highscores")
        .add({"name": _nameController.text, "score": currentScore});
  }

  //start new game after submiting the score
  Future newGame() async {
    highScoreDocId = [];
    await getDocId();
    setState(() {
      snakePositions = [0];
      foodPosition = 20;
      currentScore = 0;
      currentDirection = snakeDirections.RIGHT;
      gameStarted = false;
    });
  }

//snake current direction
  var currentDirection = snakeDirections.RIGHT;
  List<int> topGridRow = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  List<int> bottomGridRow = [90, 91, 92, 93, 94, 95, 96, 97, 98, 99];

  void snakeDirection() {
    switch (currentDirection) {
      case snakeDirections.DOWN:
        {
          if (bottomGridRow.contains(snakePositions.last)) {
            snakePositions.add(snakePositions.last - 90);
          } else {
            //add at the head
            snakePositions.add(snakePositions.last + rowsize);
          }
        }
        break;
      case snakeDirections.UP:
        {
          if (topGridRow.contains(snakePositions.last)) {
            snakePositions.add(snakePositions.last + 90);
          } else {
            //add at the head
            snakePositions.add(snakePositions.last - rowsize);
          }
        }
        break;
      case snakeDirections.RIGHT:
        {
          //if snake is at the right most end of the wall
          if ((snakePositions.last + 1) % 10 == 0) {
            snakePositions.add(snakePositions.last + 1 - rowsize);
          } else {
            if (snakePositions.contains(snakePositions.last + 1)) {
              endGame();
            } else {
              //add at the head
              snakePositions.add(snakePositions.last + 1);
            }
          }
        }
        break;
      case snakeDirections.LEFT:
        {
          if (snakePositions.last % 10 == 0) {
            snakePositions.add(snakePositions.last + rowsize - 1);
          } else {
            //add at the head
            snakePositions.add(snakePositions.last - 1);
          }
        }
        break;
    }
    if (snakePositions.last == foodPosition) {
      eatFood();
    } else {
      //remove at the tail
      snakePositions.removeAt(0);
    }
  }

  void eatFood() {
    currentScore++;
    while (snakePositions.contains(foodPosition)) {
      foodPosition = Random().nextInt(totalNoOfGrids);
    }
  }

  bool endGame() {
    //the game is over when the head touches the tail of the snake
    //this occurs when there is a duplicate in the list os snakepositions
    List<int> snakeBody = snakePositions.sublist(0, snakePositions.length - 1);
    if (snakeBody.contains(snakePositions.last)) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown) &&
              currentDirection != snakeDirections.UP) {
            currentDirection = snakeDirections.DOWN;
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp) &&
              currentDirection != snakeDirections.DOWN) {
            currentDirection = snakeDirections.UP;
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft) &&
              currentDirection != snakeDirections.RIGHT) {
            currentDirection = snakeDirections.LEFT;
          } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight) &&
              currentDirection != snakeDirections.LEFT) {
            currentDirection = snakeDirections.RIGHT;
          }
        },
        child: SafeArea(
          child: SizedBox(
            width: screenWidth > 400 ? 400 : screenWidth,
            child: Column(
              children: [
                //display the highest scores
                const SizedBox(
                  height: 5.0,
                ),
                Expanded(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //display the users current score on the left hand side
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            "Current Score: ",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            currentScore.toString(),
                            style: TextStyle(fontSize: 25),
                          )
                        ],
                      ),
                    ),
                    //and display other users scores on the right hand side of the(highest to low)
                    Expanded(
                      child: gameStarted
                          ? Container()
                          : FutureBuilder(
                              future: letsgetDocId,
                              builder: (context, snapshot) {
                                return ListView.builder(
                                    itemCount: highScoreDocId.length,
                                    itemBuilder: ((context, index) {
                                      return HighScoresTile(
                                          docId: highScoreDocId[index]);
                                    }));
                              }),
                    )
                  ],
                )),
                //game
                Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.delta.dy > 0 &&
                            currentDirection != snakeDirections.UP) {
                          currentDirection = snakeDirections.DOWN;
                        } else if (details.delta.dy < 0 &&
                            currentDirection != snakeDirections.DOWN) {
                          currentDirection = snakeDirections.UP;
                        }
                      },
                      onHorizontalDragUpdate: (details) {
                        if (details.delta.dx > 0 &&
                            currentDirection != snakeDirections.LEFT) {
                          currentDirection = snakeDirections.RIGHT;
                        } else if (details.delta.dx < 0 &&
                            currentDirection != snakeDirections.RIGHT) {
                          currentDirection = snakeDirections.LEFT;
                        }
                      },
                      child: GridView.builder(
                          itemCount: totalNoOfGrids,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: rowsize),
                          itemBuilder: (context, index) {
                            if (snakePositions.contains(index)) {
                              return const SnakePixel();
                            } else if (foodPosition == index) {
                              return const FoodPixel();
                            } else {
                              return const BlankPixel();
                            }
                          }),
                    )),
                //play button to start
                Expanded(
                    child: Container(
                  child: Center(
                    child: MaterialButton(
                      color: gameStarted ? Colors.grey : Colors.pink,
                      onPressed: () {
                        if (gameStarted == false) {
                          startGame();
                        }
                      },
                      child: Text("PLAY"),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
