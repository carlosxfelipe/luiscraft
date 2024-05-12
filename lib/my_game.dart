import 'dart:io';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyHero extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  bool collidingWithEnemy = false;

  MyHero() : super(size: Vector2.all(125));

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('luis.png');
    final hitbox = RectangleHitbox(
        size: Vector2(size.x * 0.5, size.y * 0.8),
        position: Vector2(size.x * 0.25, size.y * 0.1));
    // ..debugMode = true;
    add(hitbox);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is MyEnemy) {
      // Aqui você pode implementar o que acontece quando há uma colisão com o inimigo
      gameRef.resetGame();
    }
  }

  bool isJumping = false;
  double jumpSpeed = 0.0;

  void jump() {
    if (!isJumping && position.y >= gameRef.groundHeight - size.y) {
      isJumping = true;
      jumpSpeed = -15.0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final double speed = 100.0 * dt;

    if (gameRef.isMovingRight) {
      position.add(Vector2(speed, 0));
    }
    if (gameRef.isMovingLeft) {
      position.sub(Vector2(speed, 0));
    }

    if (isJumping) {
      position.y += jumpSpeed;
      if (Platform.isAndroid) {
        jumpSpeed += 0.25;
      } else {
        jumpSpeed += 0.5;
      }

      double groundPositionY = gameRef.groundHeight - size.y;
      if (position.y > groundPositionY) {
        position.y = groundPositionY;
        isJumping = false;
        jumpSpeed = 0.0;
      }
    }
  }
}

class MyEnemy extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  Random random = Random();
  late double speed;
  late double initialSize;

  static const Map<String, double> enemySprites = {
    'creeper.png': 75.0,
    'spider.png': 100.0,
  };

  void initializeSpeed() {
    speed = 150.0 + random.nextDouble() * 150;
  }

  Future<void> loadSpriteAndSetSize(String spriteName) async {
    sprite = await Sprite.load(spriteName);
    size = Vector2.all(enemySprites[spriteName]!);
  }

  MyEnemy(String spriteName)
      : super(size: Vector2.all(enemySprites[spriteName]!)) {
    initializeSpeed();
    loadSpriteAndSetSize(spriteName);
  }

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    final hitbox = CircleHitbox(radius: size.x * 0.5);
    // ..debugMode = true;
    add(hitbox);
  }

  Future<void> resetEnemy() async {
    String spriteName = gameRef.getRandomEnemyType();

    position.x = gameRef.size.x + size.x;
    position.y =
        gameRef.groundHeight - size.y * (0.25 + random.nextDouble() * 0.25);

    initializeSpeed();
    await loadSpriteAndSetSize(spriteName);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= speed * dt;

    if (position.x < -size.x) {
      resetEnemy();
    }
  }
}

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
    return (Random().nextBool() ? 'creeper.png' : 'spider.png');
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
    // myHero.position =
    //     Vector2(size.x / 2 - myHero.size.x / 2, groundHeight - myHero.size.y);
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
    // final Rect skyRect = Rect.fromLTWH(0, 0, size.x, size.y * 0.90);
    final Rect groundRect =
        Rect.fromLTWH(0, size.y * 0.90, size.x, size.y * 0.10);
    final Rect fullScreenRect = Rect.fromLTWH(0, 0, size.x, size.y);

    backgroundSprite.renderRect(canvas, fullScreenRect);
    canvas.drawRect(groundRect, groundPaint);

    super.render(canvas);

    scorePainter.render(canvas, 'Score: $score', Vector2(20.0, 20.0));
  }
}
