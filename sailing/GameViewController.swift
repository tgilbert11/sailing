//
//  GameViewController.swift
//  sailing
//
//  Created by Taylor H. Gilbert on 6/24/17.
//  Copyright © 2017 Taylor H. Gilbert. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    /// conversion from meters to pixels used in graphics [pixels/m]
    static let pixelsPerMeter: CGFloat = 41
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                print(scene)
                scene.scaleMode = .aspectFill
                scene.camera = SKCameraNode()
                scene.physicsWorld.contactDelegate = scene as! SKPhysicsContactDelegate
                // Present the scene
                //scene.didMove(to: view)
                view.presentScene(scene)
                //scene.didMove(to: view)
                print("done")
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            //view.showsPhysics = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

