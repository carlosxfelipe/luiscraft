import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luiscraft/characters.dart';

class MyGame extends FlameGame
    with
        HasCollisionDetection,
        KeyboardEvents,
        MultiTouchTapDetector,
        DoubleTapDetector {
  late MyHero myHero;
  late MyEnemy myEnemy;
  late Sprite backgroundSprite;
  late TextPaint scorePainter;
  int score = 0;

  bool isMovingRight = false;
  bool isMovingLeft = false;

  double get groundHeight => size.y * 0.90;

  String getRandomEnemyType() {
    var keys = enemyConfigs.keys.toList();
    return keys[Random().nextInt(keys.length)];
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    backgroundSprite = await loadSprite('scenario.png');
    String enemyType = getRandomEnemyType();
    myHero = MyHero();
    myEnemy = MyEnemy(enemyType);
    await add(myHero);
    await add(myEnemy);
    resetGame();

    scorePainter = TextPaint(
        style: const TextStyle(
            color: Colors.white, fontSize: 48.0, fontFamily: 'Arial'));
  }

  void resetGame() {
    myHero.position = Vector2(10, groundHeight - myHero.size.y);
    myEnemy.position =
        Vector2(size.x + myEnemy.size.x, groundHeight - myEnemy.size.y * 0.5);
    score = 0;
  }

  @override
  void onTapDown(int pointerId, TapDownInfo info) {
    final tapPosition = info.eventPosition.game;
    if (tapPosition.x < myHero.position.x) {
      isMovingLeft = true;
      isMovingRight = false;
    } else if (tapPosition.x > myHero.position.x + myHero.size.x) {
      isMovingRight = true;
      isMovingLeft = false;
    }
  }

  @override
  void onTapUp(int pointerId, TapUpInfo info) {
    isMovingRight = false;
    isMovingLeft = false;
  }

  @override
  void onTapCancel(int pointerId) {
    isMovingRight = false;
    isMovingLeft = false;
  }

  @override
  void onDoubleTap() {
    myHero.jump();
  }

  void incrementScore() {
    if (myHero.isJumping && myHero.jumpSpeed < 0) {
      if (myHero.position.x + myHero.size.x > myEnemy.position.x &&
          myHero.position.x < myEnemy.position.x + myEnemy.size.x) {
        if (!myHero.collidingWithEnemy) {
          score++;
          myHero.collidingWithEnemy = true;
        }
      }
    } else {
      myHero.collidingWithEnemy = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    incrementScore();
  }

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    isMovingRight = keysPressed.contains(LogicalKeyboardKey.arrowRight);
    isMovingLeft = keysPressed.contains(LogicalKeyboardKey.arrowLeft);

    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.space) {
      myHero.jump();
    }
    return KeyEventResult.handled;
  }

  @override
  void render(Canvas canvas) {
    final Paint groundPaint = Paint()..color = Colors.transparent;
    final Rect groundRect =
        Rect.fromLTWH(0, size.y * 0.90, size.x, size.y * 0.10);
    final Rect fullScreenRect = Rect.fromLTWH(0, 0, size.x, size.y);

    backgroundSprite.renderRect(canvas, fullScreenRect);
    canvas.drawRect(groundRect, groundPaint);

    super.render(canvas);

    scorePainter.render(canvas, 'Score: $score', Vector2(20.0, 20.0));
  }
}
