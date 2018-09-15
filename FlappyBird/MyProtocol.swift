//
//  MyProtocol.swift
//  FlappyBird
//
//  Created by Nathan Wainwright on 2018-09-14.
//  Copyright © 2018 Fullstack.io. All rights reserved.
//

import Foundation

protocol GameEndedDelegate {
  func didEnd (imgData: Data)
}
