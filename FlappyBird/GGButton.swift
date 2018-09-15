//
//  Buttons.swift
//  FlappyBird
//
//  Created by Nathan Wainwright on 2018-09-14.
//  Copyright © 2018 Fullstack.io. All rights reserved.
//

import SpriteKit

class GGButton: SKNode {
  var defaultButton: SKSpriteNode
  var activeButton: SKSpriteNode
  var action: () -> Void
  
  init(defaultButtonImage: String, activeButtonImage: String, buttonAction: @escaping () -> Void) {
    defaultButton = SKSpriteNode(imageNamed: defaultButtonImage)
    activeButton = SKSpriteNode(imageNamed: activeButtonImage)
    activeButton.isHidden = true
    action = buttonAction
    
    super.init()
    
    isUserInteractionEnabled = true
    addChild(defaultButton)
    addChild(activeButton)
  }
  
  /**
   Required so XCode doesn't throw warnings
   */
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
  
