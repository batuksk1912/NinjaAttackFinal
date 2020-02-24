import SpriteKit

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
  return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}

class GameScene: SKScene {
  
  struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let monster   : UInt32 = 0b1       // 1
    static let projectile: UInt32 = 0b10      // 2
  }
  
  // 1
  let player = SKSpriteNode(imageNamed: "playerone")
  let player2 = SKSpriteNode(imageNamed: "playertwo")
  var monstersDestroyedOne = 0
  var monstersDestroyedTwo = 0
  var touchLocation = CGPoint()

  override func didMove(to view: SKView){
    self.view!.isMultipleTouchEnabled = true;
    // 2
    backgroundColor = SKColor.white
    // 3
    player.position = CGPoint(x: size.width * 0.04, y: size.height * 0.3)
    player2.position = CGPoint(x: size.width * 0.96, y: size.height * 0.3)
    player.setScale(0.5)
    player2.setScale(0.5)
    // 4
    addChild(player)
    addChild(player2)
    
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
    
    run(SKAction.repeatForever(
      SKAction.sequence([
        SKAction.run(addMonster),
        SKAction.wait(forDuration: 1.0)
        ])
    ))
    
    let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
    backgroundMusic.autoplayLooped = true
    addChild(backgroundMusic)
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }
  
  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }
  
  func addMonster() {
    // Create sprite
    let monster = SKSpriteNode(imageNamed: "ball")
    monster.setScale(0.3)
    
    monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1
    monster.physicsBody?.isDynamic = true // 2
    monster.physicsBody?.categoryBitMask = PhysicsCategory.monster // 3
    monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4
    monster.physicsBody?.collisionBitMask = PhysicsCategory.none // 5
    
    // Determine where to spawn the monster along the Y axis
    let actualX = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
    
    // Position the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    monster.position = CGPoint(x: actualX, y: size.width + monster.size.width/2)
    
    // Add the monster to the scene
    addChild(monster)
    
    // Determine speed of the monster
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
    
    // Create the actions
    let actionMove = SKAction.move(to: CGPoint(x: actualX, y: -monster.size.width/2), duration: TimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()
    let loseAction = SKAction.run() { [weak self] in
      guard let `self` = self else { return }
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false, scoreOne: String(self.monstersDestroyedOne), scoreTwo:String(self.monstersDestroyedTwo) )
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
    monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    // 1 - Choose one of the touches to work with
    guard let touch = touches.first else {
      return
    }
    run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
    
    touchLocation = touch.location(in: self)
    
    // 2 - Set up initial location of projectile
    let projectile = SKSpriteNode(imageNamed: "projectile")
    let projectile2 = SKSpriteNode(imageNamed: "projectile")
    projectile.position = player.position
    projectile2.position = player2.position

    
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster
    projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
    projectile.physicsBody?.usesPreciseCollisionDetection = true
    
    projectile2.physicsBody = SKPhysicsBody(circleOfRadius: projectile2.size.width/2)
       projectile2.physicsBody?.isDynamic = true
       projectile2.physicsBody?.categoryBitMask = PhysicsCategory.projectile
       projectile2.physicsBody?.contactTestBitMask = PhysicsCategory.monster
       projectile2.physicsBody?.collisionBitMask = PhysicsCategory.none
       projectile2.physicsBody?.usesPreciseCollisionDetection = true
    
    // 3 - Determine offset of location to projectile
    let offset = touchLocation - projectile.position
    let offset2 = touchLocation - projectile2.position

    
    // 4 - Bail out if you are shooting down or backwards
    if offset.x < 0 { return }
    if offset2.x > 0 { return }
    
    // 5 - OK to add now - you've double checked position
    addChild(projectile)
    addChild(projectile2)
    
    // 6 - Get the direction of where to shoot
    let direction = offset.normalized()
    let direction2 = offset2.normalized()
    
    // 7 - Make it shoot far enough to be guaranteed off screen
    let shootAmount = direction * 1000
    let shootAmount2 = direction2 * 1000
    
    // 8 - Add the shoot amount to the current position
    let realDest = shootAmount + projectile.position
    let realDest2 = shootAmount2 + projectile2.position
    
    // 9 - Create the actions
     if touchLocation.x > (self.view?.frame.midX)! {
               let actionMove2 = SKAction.move(to: realDest2, duration: 2.0)
               let actionMoveDone2 = SKAction.removeFromParent()
               projectile2.run(SKAction.sequence([actionMove2, actionMoveDone2]))
      projectile.removeFromParent()
             } else {
               let actionMove = SKAction.move(to: realDest, duration: 2.0)
                       let actionMoveDone = SKAction.removeFromParent()
                       projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
      projectile2.removeFromParent()
             }
  }
  
  func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
    run(SKAction.playSoundFileNamed("gun-shot.wav", waitForCompletion: false))
       print("Hit")
       let fire = SKEmitterNode(fileNamed: "explode")
       fire?.position = monster.position
       addChild(fire!)
       fire?.particleLifetime = 0.1
       projectile.removeFromParent()
       monster.removeFromParent()
       let waitAction = SKAction.wait(forDuration: TimeInterval(fire!.particleLifetime + (fire!.particleLifetimeRange/2.0)))
       fire!.run(waitAction, completion: {
         fire!.removeFromParent()
       })
    if touchLocation.x > (self.view?.frame.midX)! {
    monstersDestroyedTwo += 1
    } else {
      monstersDestroyedOne += 1
    }
    print(monstersDestroyedTwo)
    print(monstersDestroyedOne)
    if monstersDestroyedOne + monstersDestroyedTwo > 29 {
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: true, scoreOne: String(monstersDestroyedOne), scoreTwo:String(monstersDestroyedTwo) )
      view?.presentScene(gameOverScene, transition: reveal)
    }
  }
}

extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    // 1
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
    
    // 2
    if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
      (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
      if let monster = firstBody.node as? SKSpriteNode,
        let projectile = secondBody.node as? SKSpriteNode {
        projectileDidCollideWithMonster(projectile: projectile, monster: monster)
      }
    }
  }
}
