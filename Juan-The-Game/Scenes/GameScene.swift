//
//  GameScene.swift
//  Juan-The-Game
//

import SpriteKit
import CoreMotion

class GameScene: SKScene {
    
    var motionManager: CMMotionManager!
    let ball = SKSpriteNode(imageNamed: "bitcoin")
    var platforms = [SKSpriteNode]()
    var bottom = SKShapeNode()
    let platform1 = SKSpriteNode(imageNamed: "platform1")
    let scoreLabel = SKLabelNode(text: "Score: 0")
    var score = 0
    var highestScore = 0
    var isGameStarted = false
    let playJumpSound = SKAction.playSoundFileNamed("jump", waitForCompletion: false)
    let playBreakSound = SKAction.playSoundFileNamed("break", waitForCompletion: false)
    var isSuperJumpOn = false
    var superJumpCounter: CGFloat = 0
    
    override func didMove(to view: SKView) {
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        layoutScene()
    }
    
    func layoutScene() {
        addBackground()
        addScoreCounter()
        spawnBall()
        addBottom()
        makePlatforms()
    }
    
    func addBackground() {
            let background = SKSpriteNode(imageNamed: "background")
            background.position = CGPoint(x: frame.midX, y: frame.midY)
    //        background.size = background.texture!.size()
            background.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            background.zPosition = ZPositions.background
            addChild(background)
        }
    
    func addScoreCounter() {
        scoreLabel.fontSize = 24.0
        scoreLabel.fontName = "HelveticaNeue-Bold"
        scoreLabel.fontColor = UIColor.init(red: 38/255, green: 120/255, blue: 95/255, alpha: 1)
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .left
        
        // Position scoreLabel on the left side of the screen
        scoreLabel.position = CGPoint(x: 20, y: frame.height - (view?.safeAreaInsets.top ?? 10) - 20)
        scoreLabel.zPosition = ZPositions.scoreLabel
        addChild(scoreLabel)
    }
    
    func spawnBall() {
        ball.name = "Ball"
        ball.position = CGPoint(x: frame.midX, y: 20 + ball.size.height/2)
        ball.zPosition = ZPositions.ball
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width/2)
        ball.physicsBody?.affectedByGravity = true
        ball.physicsBody?.categoryBitMask = PhysicsCategories.ballCategory
        ball.physicsBody?.contactTestBitMask = PhysicsCategories.platformCategory | PhysicsCategories.dollarWithHoleCategory | PhysicsCategories.tweet
        ball.physicsBody?.collisionBitMask = PhysicsCategories.none
        addChild(ball)
    }
    
    func addBottom() {
        bottom = SKShapeNode(rectOf: CGSize(width: frame.width*2, height: 20))
        bottom.position = CGPoint(x: frame.midX, y: 10)
        bottom.fillColor = UIColor.init(red: 25/255, green: 105/255, blue: 81/255, alpha: 1)
        bottom.strokeColor = bottom.fillColor
        bottom.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 20))
        bottom.physicsBody?.affectedByGravity = false
        bottom.physicsBody?.isDynamic = false
        bottom.physicsBody?.categoryBitMask = PhysicsCategories.platformCategory
        addChild(bottom)
    }
    
    func makePlatforms() {
        let spaceBetweenPlatforms = frame.size.height/10
        for i in 0..<Int(frame.size.height/spaceBetweenPlatforms) {
            let x = CGFloat.random(in: 0...frame.size.width)
            let y = CGFloat.random(in: CGFloat(i)*spaceBetweenPlatforms+10...CGFloat(i+1)*spaceBetweenPlatforms-10)
            spawnPlatform(at: CGPoint(x: x, y: y))
        }
    }
    
    func spawnPlatform(at position: CGPoint) {
        var platform = SKSpriteNode()
        if position.x < frame.midX {
            platform = SKSpriteNode(imageNamed: "dollarLeft")
        }
        else {
            platform = SKSpriteNode(imageNamed: "dollarRight")
        }
        platform.position = position
        platform.zPosition = ZPositions.platform
        platform.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: platform.size.width, height: platform.size.height))
        platform.physicsBody?.categoryBitMask = PhysicsCategories.platformCategory
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.affectedByGravity = false
        platforms.append(platform)
        addChild(platform)
    }
    
    override func update(_ currentTime: TimeInterval) {
        checkPhoneTilt()
        if isGameStarted {
            checkBallPosition()
            checkBallVelocity()
            updatePlatformsPositions()
        }
    }
    
    func checkPhoneTilt() {
        var defaultAcceleration = 9.8
        if let accelerometerData = motionManager.accelerometerData {
            var xAcceleration = accelerometerData.acceleration.x * 20
            if xAcceleration > defaultAcceleration {
                xAcceleration = defaultAcceleration
            }
            else if xAcceleration < -defaultAcceleration {
                xAcceleration = -defaultAcceleration
            }
            ball.run(SKAction.rotate(toAngle: CGFloat(-xAcceleration/5), duration: 0.15))
            if isGameStarted {
                if isSuperJumpOn {
                    defaultAcceleration = -0.1
                }
                physicsWorld.gravity = CGVector(dx: xAcceleration, dy: -defaultAcceleration)
            }
        }
    }
    
    func checkBallPosition() {
        let ballWidth = ball.size.width
        if ball.position.y+ballWidth < 0 {
            run(SKAction.playSoundFileNamed("gameOver", waitForCompletion: false))
            saveScore()
            let menuScene = MenuScene.init(size: view!.bounds.size)
            view?.presentScene(menuScene)
        }
        setScore()
        if ball.position.x-ballWidth >= frame.size.width || ball.position.x+ballWidth <= 0 {
            fixBallPosition()
        }
    }
    
    func saveScore() {
        UserDefaults.standard.setValue(highestScore, forKey: "LastScore")
        if highestScore > UserDefaults.standard.integer(forKey: "HighScore") {
            UserDefaults.standard.setValue(highestScore, forKey: "HighScore")
        }
    }
    
    func setScore() {
        let oldScore = score
        score = (Int(ball.position.y) - Int(ball.size.height/2)) - (Int(bottom.position.y) - Int(bottom.frame.size.height)/2)
        score = score < 0 ? 0 : score
        if score > oldScore {
            scoreLabel.fontColor = UIColor.init(red: 38/255, green: 120/255, blue: 95/255, alpha: 1)
            if score > highestScore {
                highestScore = score
            }
        }
        else {
            scoreLabel.fontColor = UIColor.init(red: 136/255, green: 24/255, blue: 0/255, alpha: 1)
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.locale = Locale(identifier: "en_US")
        let formattedScore = numberFormatter.string(from: NSNumber(value: score))
        scoreLabel.text = "Score: " + (formattedScore ?? "0")
    }
    
    func checkBallVelocity() {
        if let ballVelocity = ball.physicsBody?.velocity.dx {
            if ballVelocity > 1000 {
                ball.physicsBody?.velocity.dx = 1000
            }
            else if ballVelocity < -1000 {
                ball.physicsBody?.velocity.dx = -1000
            }
        }
    }
    
    func updatePlatformsPositions() {
        var minimumHeight: CGFloat = frame.size.height/2
        guard let ballVelocity = ball.physicsBody?.velocity.dy else {
            return
        }
        var distance = ballVelocity/50
        if isSuperJumpOn {
            minimumHeight = 0
            distance = 30 - superJumpCounter
            superJumpCounter += 0.16
        }
        if ball.position.y > minimumHeight && ballVelocity > 0 {
            for platform in platforms {
                platform.position.y -= distance
                if platform.position.y < 0-platform.frame.size.height/2 {
                    update(platform: platform, positionY: platform.position.y)
                }
            }
            bottom.position.y -= distance
        }
    }
    
    func update(platform: SKSpriteNode, positionY: CGFloat) {
        platform.position.x = CGFloat.random(in: 0...frame.size.width)
        
        var direction = "Left"
        if platform.position.x > frame.midX {
            direction = "Right"
        }
        
        platform.removeAllActions()
        platform.alpha = 1.0
        if Int.random(in: 1...35) == 1 {
            platform.texture = SKTexture(imageNamed: "tweet")
            updateSizeOf(platform: platform)
            platform.physicsBody?.categoryBitMask = PhysicsCategories.tweet
        }
        else if Int.random(in: 1...5) == 1 {
            platform.texture = SKTexture(imageNamed: "strapOfDollars" + direction)
            updateSizeOf(platform: platform)
            platform.physicsBody?.categoryBitMask = PhysicsCategories.platformCategory
            if direction == "Left" {
                platform.position.x = 0
                animate(platform: platform, isLeft: true)
            }
            else {
                platform.position.x = frame.size.width
                animate(platform: platform, isLeft: false)
            }
        }
        else if Int.random(in: 1...5) == 1 {
            platform.texture = SKTexture(imageNamed: "dollarWithHole" + direction)
            updateSizeOf(platform: platform)
            platform.physicsBody?.categoryBitMask = PhysicsCategories.dollarWithHoleCategory
        }
        else {
            platform.texture = SKTexture(imageNamed: "dollar" + direction)
            updateSizeOf(platform: platform)
            platform.physicsBody?.categoryBitMask = PhysicsCategories.platformCategory
        }
        
        platform.position.y = frame.size.height + platform.frame.size.height/2 + platform.position.y
    }
    
    func updateSizeOf(platform: SKSpriteNode) {
        if let textureSize = platform.texture?.size() {
            platform.size = CGSize(width: textureSize.width, height: textureSize.height)
            platform.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: platform.size.width, height: platform.size.height))
            platform.physicsBody?.isDynamic = false
            platform.physicsBody?.affectedByGravity = false
        }
    }
    
    func animate(platform: SKSpriteNode, isLeft: Bool) {
        let distanceX = isLeft ? frame.size.width : -frame.size.width
        platform.run(SKAction.moveBy(x: distanceX, y: 0, duration: 2)) {
            platform.run(SKAction.moveBy(x: -distanceX, y: 0, duration: 2)) {
                self.animate(platform: platform, isLeft: isLeft)
            }
        }
    }
    
    func fixBallPosition() {
        let ballWidth = ball.size.width
        if ball.position.x >= frame.size.width {
            ball.position.x = 0 - ballWidth/2+1
        }
        else {
            ball.position.x = frame.size.width + ballWidth/2-1
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isGameStarted {
            ball.physicsBody?.velocity.dy = frame.size.height*1.2 - ball.position.y
            isGameStarted = true
            run(playJumpSound)
        }
    }

}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if let ballVelocity = ball.physicsBody?.velocity.dy {
            if ballVelocity < 0 {
                if contactMask == PhysicsCategories.ballCategory | PhysicsCategories.platformCategory {
                    run(playJumpSound)
                    ball.physicsBody?.velocity.dy = frame.size.height*1.2 - ball.position.y
                }
                else if contactMask == PhysicsCategories.ballCategory | PhysicsCategories.dollarWithHoleCategory {
                    run(playJumpSound)
                    run(playBreakSound)
                    ball.physicsBody?.velocity.dy = frame.size.height*1.2 - ball.position.y
                    if let platform = (contact.bodyA.node?.name != "Ball") ? contact.bodyA.node as? SKSpriteNode : contact.bodyB.node as? SKSpriteNode {
                        platform.physicsBody?.categoryBitMask = PhysicsCategories.none
                        platform.run(SKAction.fadeOut(withDuration: 0.5))
                    }
                }
                else if contactMask == PhysicsCategories.ballCategory | PhysicsCategories.tweet {
                    run(SKAction.playSoundFileNamed("superJump", waitForCompletion: false))
                    ball.physicsBody?.velocity.dy = 10
                    isSuperJumpOn = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.isSuperJumpOn = false
                        self.superJumpCounter = 0
                    }
                }
            }
        }
    }
}
