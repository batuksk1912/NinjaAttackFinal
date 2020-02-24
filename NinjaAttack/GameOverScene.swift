import Foundation
import SpriteKit

class GameOverScene: SKScene {
  init(size: CGSize, won:Bool, scoreOne: String, scoreTwo:String) {
    super.init(size: size)
    
    // 1
    backgroundColor = SKColor.white
    
    // 2
    let message = won ? "Game Won!" : "Game Over :["
    
    // 3
    let label = SKLabelNode(fontNamed: "Chalkduster")
    label.text = message
    label.fontSize = 40
    label.fontColor = SKColor.black
    label.position = CGPoint(x: size.width/2, y: size.height/2)
    addChild(label)
    
    let scoreO = SKLabelNode(fontNamed: "Chalkduster")
    scoreO.text = "Player 1 Score: " + scoreOne
    scoreO.fontSize = 16
    scoreO.fontColor = SKColor.black
    scoreO.position = CGPoint(x: size.width/2, y: size.height/3)
    addChild(scoreO)
    
    let scoreT = SKLabelNode(fontNamed: "Chalkduster")
    scoreT.text = "Player 2 Score: " + scoreTwo
    scoreT.fontSize = 16
    scoreT.fontColor = SKColor.black
    scoreT.position = CGPoint(x: size.width/2, y: size.height/4)
    addChild(scoreT)
    
    // 4
    run(SKAction.sequence([
      SKAction.wait(forDuration: 3.0),
      SKAction.run() { [weak self] in
        // 5
        guard let `self` = self else { return }
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        let scene = GameScene(size: size)
        self.view?.presentScene(scene, transition:reveal)
      }
      ]))
  }
  
  // 6
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
