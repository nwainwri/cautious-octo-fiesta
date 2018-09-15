//
//  GameScene.swift
//  FlappyBird
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate
{
  
  var gameEndDelegate: GameEndedDelegate?
  
  let verticalPipeGap = 150.0
  
  var bird:SKSpriteNode!
  var skyColor:SKColor!
  var pipeTextureUp:SKTexture!
  var pipeTextureDown:SKTexture!
  var movePipesAndRemove:SKAction!
  var moving:SKNode!
  var pipes:SKNode!
  var canRestart = Bool()
  var scoreLabelNode:SKLabelNode!
  var score = NSInteger()
  
  let birdCategory: UInt32 = 1 << 0
  let worldCategory: UInt32 = 1 << 1
  let pipeCategory: UInt32 = 1 << 2
  let scoreCategory: UInt32 = 1 << 3
  
  //properties addon:
  
  //  var newGameButton:SKNode!
  var endMenu = UIView()
  var playAgain = UIButton()
  var shareScreen = UIButton()
  var myLabel:SKLabelNode!
//  var myLabel = UILabel()
  
  var gameOverScreenShot: UIImage!
  
//  var gameOverBlockSprite = SKSpriteNode(imageNamed: "PipeUp")
  
  
  
  
  override func didMove(to view: SKView) {
    
    canRestart = true
    
    // setup physics
    self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 )
    self.physicsWorld.contactDelegate = self
    
    // setup background color
    skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
    self.backgroundColor = skyColor
    
    moving = SKNode()
    self.addChild(moving)
    pipes = SKNode()
    moving.addChild(pipes)
    
    // ground
    let groundTexture = SKTexture(imageNamed: "land")
    groundTexture.filteringMode = .nearest // shorter form for SKTextureFilteringMode.Nearest
    
    let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
    let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
    let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
    
    for i in 0 ..< 2 + Int(self.frame.size.width / ( groundTexture.size().width * 2 )) {
      let i = CGFloat(i)
      let sprite = SKSpriteNode(texture: groundTexture)
      sprite.setScale(2.0)
      sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0)
      sprite.run(moveGroundSpritesForever)
      moving.addChild(sprite)
    }
    
    // skyline
    let skyTexture = SKTexture(imageNamed: "sky")
    skyTexture.filteringMode = .nearest
    
    let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
    let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
    let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
    
    for i in 0 ..< 2 + Int(self.frame.size.width / ( skyTexture.size().width * 2 )) {
      let i = CGFloat(i)
      let sprite = SKSpriteNode(texture: skyTexture)
      sprite.setScale(2.0)
      sprite.zPosition = -20
      sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
      sprite.run(moveSkySpritesForever)
      moving.addChild(sprite)
    }
    
    // create the pipes textures
    pipeTextureUp = SKTexture(imageNamed: "PipeUp")
    pipeTextureUp.filteringMode = .nearest
    pipeTextureDown = SKTexture(imageNamed: "PipeDown")
    pipeTextureDown.filteringMode = .nearest
    
    // create the pipes movement actions
    let distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTextureUp.size().width)
    let movePipes = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
    let removePipes = SKAction.removeFromParent()
    movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
    
    // spawn the pipes
    let spawn = SKAction.run(spawnPipes)
    let delay = SKAction.wait(forDuration: TimeInterval(2.0))
    let spawnThenDelay = SKAction.sequence([spawn, delay])
    let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
    self.run(spawnThenDelayForever)
    
    // setup our bird
    let birdTexture1 = SKTexture(imageNamed: "bird-01")
    birdTexture1.filteringMode = .nearest
    let birdTexture2 = SKTexture(imageNamed: "bird-02")
    birdTexture2.filteringMode = .nearest
    
    let anim = SKAction.animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.2)
    let flap = SKAction.repeatForever(anim)
    
    bird = SKSpriteNode(texture: birdTexture1)
    bird.setScale(2.0)
    bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
    bird.run(flap)
    
    
    bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
    bird.physicsBody?.isDynamic = true
    bird.physicsBody?.allowsRotation = false
    
    bird.physicsBody?.categoryBitMask = birdCategory
    bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
    bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
    
    self.addChild(bird)
    
    // create the ground
    let ground = SKNode()
    ground.position = CGPoint(x: 0, y: groundTexture.size().height)
    ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
    ground.physicsBody?.isDynamic = false
    ground.physicsBody?.categoryBitMask = worldCategory
    self.addChild(ground)
    
    // Initialize label and create a label which holds the score
    score = 0
    scoreLabelNode = SKLabelNode(fontNamed:"MarkerFelt-Wide")
    scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3 * self.frame.size.height / 4 )
    scoreLabelNode.zPosition = 100
    scoreLabelNode.text = String(score)
    self.addChild(scoreLabelNode)
    
  }
  
  func spawnPipes() {
    let pipePair = SKNode()
    pipePair.position = CGPoint( x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0 )
    pipePair.zPosition = -10
    
    let height = UInt32( self.frame.size.height / 4)
    let y = Double(arc4random_uniform(height) + height)
    
    let pipeDown = SKSpriteNode(texture: pipeTextureDown)
    pipeDown.setScale(2.0)
    pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height) + verticalPipeGap)
    
    
    pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
    pipeDown.physicsBody?.isDynamic = false
    pipeDown.physicsBody?.categoryBitMask = pipeCategory
    pipeDown.physicsBody?.contactTestBitMask = birdCategory
    pipePair.addChild(pipeDown)
    
    let pipeUp = SKSpriteNode(texture: pipeTextureUp)
    pipeUp.setScale(2.0)
    pipeUp.position = CGPoint(x: 0.0, y: y)
    
    pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
    pipeUp.physicsBody?.isDynamic = false
    pipeUp.physicsBody?.categoryBitMask = pipeCategory
    pipeUp.physicsBody?.contactTestBitMask = birdCategory
    pipePair.addChild(pipeUp)
    
    let contactNode = SKNode()
    contactNode.position = CGPoint( x: pipeDown.size.width + bird.size.width / 2, y: self.frame.midY )
    contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
    contactNode.physicsBody?.isDynamic = false
    contactNode.physicsBody?.categoryBitMask = scoreCategory
    contactNode.physicsBody?.contactTestBitMask = birdCategory
    pipePair.addChild(contactNode)
    
    pipePair.run(movePipesAndRemove)
    pipes.addChild(pipePair)
    
  }
  
  
  func resetScene (){
    //      print("DEAD? not first death... ")
    
    // Move bird to original position and reset velocity
    bird.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
    bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
    bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
    bird.speed = 1.0
    bird.zRotation = 0.0
    
    // Remove all existing pipes
    pipes.removeAllChildren()
    
    // Reset _canRestart
    canRestart = false
    
    // Reset score
    score = 0
    scoreLabelNode.text = String(score)
    
    
    
    // Restart animation
    moving.speed = 1
  }
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if moving.speed > 0  {
      for _ in touches { // do we need all touches?
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30))
        // MARK: ADDED THIS- - button test attempt
        
        //        let location = touch.location(in: self)
        //
        //        if (atPoint(location).name == "newGame_button"){
        //          resetScene()
        //          print("RESTARTED")
        //        }
        
        // -- ADDED THIS
      }
      //          print("FLYING")
      
    } else if canRestart {
      //          print("triggers restart of game")
      self.resetScene()
      // MARK: reset labels an buttons to hide after reset OR share
      playAgain.isHidden = true
      shareScreen.isHidden = true
      myLabel.isHidden = true
      endMenu.isHidden = true
      //      endMenu.isHidden = true
      
    }
  }
  
  override func update(_ currentTime: TimeInterval) {
    /* Called before each frame is rendered */
    let value = bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 )
    bird.zRotation = min( max(-1, value), 0.5 )
  }
  
  func didBegin(_ contact: SKPhysicsContact) {
    if moving.speed > 0 {
      if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
        // Bird has contact with score entity
        score += 1
        scoreLabelNode.text = String(score)
        
        // Add a little visual feedback for the score increment
        scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
      } else {
        
        moving.speed = 0
        
        bird.physicsBody?.collisionBitMask = worldCategory
        bird.run(  SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1), completion:{self.bird.speed = 0 })
        //               MARK: spot where bird "dies"
        print("ACTUAL DEATH???")
        
        gameOverScreenShot = getScreenshot()
        // CALL DELEGATE METHOD HERE
        // OR CALL FUNCTION HERE THAT CALLS DELEGATE INSIDE IT
        
        //        sendData()
        //        let gameOverShot = getScreenshot()
        //MARK: setup for labels and buttons
        //        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        //        let displaySize: CGRect = UIScreen.main.bounds
        //        let displayWidth = displaySize.width
        //        let displayHeight = displaySize.height
        
        
        
        //        newGameButton = SKSpriteNode(imageNamed: "bird-01")
        //        newGameButton.position = CGPoint(x: frame.width/3, y: frame.height/2)
        //        self.addChild(newGameButton)
        //        newGameButton.name = "newGame_button"
        //        newGameButton.isHidden = true
        
        //        let button: GGButton = GGButton(defaultButtonImage: "PipeUp", activeButtonImage: "PipeDown", buttonAction: getScreenshot)
        //        button.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        //        addChild(button)
        //        button.isHidden = true
        
        
        endMenu.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        endMenu.backgroundColor = UIColor.darkGray
        endMenu.alpha = 0.5
        endMenu.center = (self.view?.center)!
        endMenu.isUserInteractionEnabled = true
        
//        endMenu.isMultipleTouchEnabled = false
//        endMenu.isExclusiveTouch = true
                self.view?.addSubview(endMenu)

//        gameOverBlockSprite = SKSpriteNode(imageNamed: "PipeUp")
//        gameOverBlockSprite.size = CGSize(width: 500, height: 700)
//        gameOverBlockSprite.color = UIColor.clear
//        gameOverBlockSprite.zPosition = 1
//        gameOverBlockSprite.position = CGPoint(x: 0, y: 0)
//        gameOverBlockSprite.isHidden = false
//        self.addChild(gameOverBlockSprite)
        
        
        myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "GameOver!"
        myLabel.fontSize = 65
        myLabel.position = CGPoint(x: frame.width/2, y: frame.height/2)
        //        myLabel.zPosition = 3
        self.addChild(myLabel)
        
        
        
        //THIS WORKS AS A BUTTON
        //        let playAgain = UIButton()
        playAgain.frame = CGRect(x: 0 , y: 0, width: 75, height: 25)
        let playAgainImg = UIImage(named: "restart")
        playAgain.setImage(playAgainImg, for: .normal)
        //        playAgain.frame = CGRect(x: frame.width/2, y: frame.height/2, width: 100, height: 36)
        playAgain.backgroundColor = UIColor.red
        playAgain.center = CGPoint(x: 50, y: frame.height/4)
        //        playAgain.center = (self.view?.center)!
        self.view?.addSubview(playAgain)
        playAgain.addTarget(self, action: #selector(newGame(_:)), for: .touchUpInside)
        // -- END
        
        //THIS WORKS AS A BUTTON
        //        let playAgain = UIButton()
        shareScreen.frame = CGRect(x: 0 , y: 0, width: 75, height: 25)
        let shareScoreImg = UIImage(named: "share")
        shareScreen.setImage(shareScoreImg, for: .normal)
        //        shareScreen.imageView?.image = UIImage(contentsOfFile: "PipeUp")
        //        playAgain.frame = CGRect(x: frame.width/2, y: frame.height/2, width: 100, height: 36)
        shareScreen.backgroundColor = UIColor.purple
        shareScreen.center = CGPoint(x: 200, y: frame.height/4)
        //        playAgain.center = (self.view?.center)!
        self.view?.addSubview(shareScreen)
        shareScreen.addTarget(self, action: #selector(playAgainTapped(_:)), for: .touchUpInside)
        // -- END
        
        
        
        
        playAgain.isHidden = false
        shareScreen.isHidden = false
                endMenu.isHidden = false
        myLabel.isHidden = false
        
        
        // Flash background if contact is detected
        self.removeAction(forKey: "flash")
        self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
          self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
        }),SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
          self.backgroundColor = self.skyColor
        }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
          self.canRestart = true
        })]), withKey: "flash")
      }
      
    }
    
    
  }
  
  
  // addon functions
  func getScreenshot() -> UIImage {
    let myScreen = self
    let snapshotView = myScreen.view!.snapshotView(afterScreenUpdates: true)
    let bounds = UIScreen.main.bounds
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
    snapshotView?.drawHierarchy(in: bounds, afterScreenUpdates: true)
    let screenshotImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()! // MARK: REMOVE '!'
    UIGraphicsEndImageContext()
    print("SCREENSHOT")
    return screenshotImage;
  }
  
  
  func sendData ()
  {
    //      gameEndDelegate?.didEnd(imgData: <#T##Data#>)
    print("BUTTON ")
  }
  
  
  //MARK: function so far to call button items and such... use this for reset
  // make a second one to add sharing.
  @objc func playAgainTapped(_ sender: Any?) -> Void {
    print("Play again was Tapped!")
    shareScore()
    //    resetScene()
    // take whatever action you want here
  }
  
  @objc func newGame(_ sender: Any?) -> Void {
    print("restart Button tapped")
    playAgain.isHidden = true
    shareScreen.isHidden = true
    myLabel.isHidden = true
    endMenu.isHidden = true
    resetScene()
  }
  
  
  func shareScore() {
    let postText: String = "Check out my score! Can you beat it?"
    // MARK: seems to take screenshot AFTER reset.
    
    // MARK: NEED TO SET SCREENSHOT ONCE DEATH HAPPENS ; SAVE THAT IMAGE AND ONLY USE IT DURING SHARE/RESET.
    //
    //    [access] This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSPhotoLibraryAddUsageDescription key with a string value explaining to the user how the app uses this data.
    //
    //    had to add this
    //
    //    <key>NSPhotoLibraryAddUsageDescription</key>
    //    <string>Our application needs permission to write photos...</string>
    let postImage: UIImage = gameOverScreenShot
    let activityItems = [postText, postImage] as [Any]
    let activityController = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )
    
    let controller: UIViewController = self.view!.window!.rootViewController!
    
    controller.present(
      activityController,
      animated: true,
      completion: nil
    )
  }
  
  //  func getScreenshoted(scene: SKScene) -> UIImage {
  //    let snapshotView = scene.view!.snapshotView(afterScreenUpdates: true)
  //    let bounds = UIScreen.main.bounds
  //
  //    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
  //
  //    snapshotView?.drawHierarchy(in: bounds, afterScreenUpdates: true)
  //
  //    var screenshotImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
  //
  //    UIGraphicsEndImageContext()
  //
  //    return screenshotImage;
  //  }
  
  
  
}
