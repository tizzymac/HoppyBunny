//
//  GameScene.swift
//  HoppyBunny
//
//  Created by Tizzy Macgregor on 2/7/22.
//

import SpriteKit

enum GameSceneState {
    case active, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let scrollSpeed: CGFloat = 100
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 /* 60 FPS */
    
    var hero: SKSpriteNode!
    var scrollLayer: SKNode!
    var obstacleSource: SKNode!
    var obstacleLayer: SKNode!
    var spawnTimer: CFTimeInterval = 0
    var buttonRestart: MSButtonNode!
    var gameState: GameSceneState = .active
    var scoreLabel: SKLabelNode!
    var points = 0
    
    override func didMove(to view: SKView) {
        /* Recursive node search for 'hero' (child of referenced node) */
        hero = (self.childNode(withName: "//hero") as! SKSpriteNode)

        /* allows the hero to animate when it's in the GameScene */
        hero.isPaused = false
        
        scrollLayer = self.childNode(withName: "scrollLayer")
        
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        obstacleSource = obstacleLayer.childNode(withName: "obstacle")
        
        physicsWorld.contactDelegate = self
        
        /* Setup restart button selection handler */
        buttonRestart = (self.childNode(withName: "buttonRestart") as! MSButtonNode)
        buttonRestart.selectedHandler = {

          /* Grab reference to our SpriteKit view */
          let skView = self.view as SKView?

          /* Load Game scene */
          let scene = GameScene(fileNamed:"GameScene") as GameScene?

          /* Ensure correct aspect mode */
          scene?.scaleMode = .aspectFill

          /* Restart game scene */
          skView?.presentScene(scene)
        }
        
        /* Hide restart button */
        buttonRestart.state = .MSButtonNodeStateHidden
        
        scoreLabel = (self.childNode(withName: "scoreLabel") as! SKLabelNode)
        
        /* Reset Score label */
        scoreLabel.text = "\(points)"
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Disable touch if game state is not active */
        if gameState != .active { return }
        
        /* Apply vertical impulse */
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
    }

    /* Called before each frame is rendered */
    override func update(_ currentTime: TimeInterval) {
        /* Skip game update if game no longer active */
        if gameState != .active { return }
        
        /* Grab current velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0

        /* Check and cap vertical velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
    
        scrollWorld()
        updateObstacles()
        
        spawnTimer+=fixedDelta
    }
    
    func scrollWorld() {
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
                
        /* Loop through scroll layer nodes */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func updateObstacles() {
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)

        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {

            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)

            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= -26 {
            // 26 is one half the width of an obstacle

                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
        }
        
        /* Time to add a new obstacle? */
        if spawnTimer >= 1.5 {

            /* Create a new obstacle by copying the source obstacle */
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)

            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition =  CGPoint(x: 347, y: CGFloat.random(in: 234...382))

            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)

            // Reset spawn timer
            spawnTimer = 0
        }
    }
    
    /* Hero touches anything, game over */
    func didBegin(_ contact: SKPhysicsContact) {
        /* Get references to bodies involved in collision */
        let contactA = contact.bodyA
        let contactB = contact.bodyB

        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!

        /* Did our hero pass through the 'goal'? */
        if nodeA.name == "goal" || nodeB.name == "goal" {

          /* Increment points */
          points += 1

          /* Update score label */
          scoreLabel.text = String(points)

          /* We can return now */
          return
        }

        /* Ensure only called while game running */
        if gameState != .active { return }

        /* Change game state to game over */
        gameState = .gameOver

        /* Stop hero flapping animation */
        hero.removeAllActions()

        /* Show restart button */
        buttonRestart.state = .MSButtonNodeStateActive
    }
}
