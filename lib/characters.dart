import 'dart:io';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:luiscraft/my_game.dart';

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

class EnemyConfig {
  final double minSize;
  final double maxSize;
  final double baseSpeed;

  EnemyConfig(
      {required this.minSize, required this.maxSize, required this.baseSpeed});
}

Map<String, EnemyConfig> enemyConfigs = {
  'creeper.png': EnemyConfig(minSize: 75.0, maxSize: 100.0, baseSpeed: 150.0),
  'spider.png': EnemyConfig(minSize: 100.0, maxSize: 125.0, baseSpeed: 150.0),
  // Adicionar novos inimigos aqui
};

class MyEnemy extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  Random random = Random();
  late double speed;
  late double initialSize;

  void initializeSpeed(String spriteName) {
    var config = enemyConfigs[spriteName]!;
    speed = config.baseSpeed + random.nextDouble() * 150;
  }

  Future<void> loadSpriteAndSetSize(String spriteName) async {
    sprite = await Sprite.load(spriteName);
    var config = enemyConfigs[spriteName]!;
    double randomSize = config.minSize +
        random.nextDouble() * (config.maxSize - config.minSize);
    size = Vector2.all(randomSize);
    speed = config.baseSpeed + random.nextDouble() * 150;
  }

  MyEnemy(String spriteName)
      : super(size: Vector2.all(enemyConfigs[spriteName]!.minSize)) {
    initializeSpeed(spriteName);
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

    initializeSpeed(spriteName);
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
