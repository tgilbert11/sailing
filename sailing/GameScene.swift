//
//  GameScene.swift
//  sailing
//
//  Created by Taylor H. Gilbert on 6/24/17.
//  Copyright © 2017 Taylor H. Gilbert. All rights reserved.
//

import SpriteKit
import GameplayKit

infix operator ⋅ : MultiplicationPrecedence
infix operator ⊙ : MultiplicationPrecedence

class GameScene: SKScene {
    
    // Game Control
    private let rotateBoatNotView = true
    private let boat = Catalina_142.init(pixelsPerMeter: GameViewController.pixelsPerMeter)
    /// [m/s]
    private var v_Tŵ = CGVector(dx: 0, dy: 6)
    
    // simulation information
    /// [s]
    private var lastSceneUpdateTime: TimeInterval = 0
    /// [pixels]
    private var sceneWidth: CGFloat?
    /// [pixels]
    private var sceneHeight: CGFloat?
    /// single-sided overlap in x and y of consecutive background tiles [pixels]
    private var bgOverlap: CGFloat = 5
    /// position of center of scene relative to real world [pixels]
    private var sceneShift = CGPoint.zero
    /// position of background center relative to world to follow scene center [pixels]
    private var backgroundCenterRelativeToWorld = CGPoint.zero // pixels
    
    // UI input things
    /// maximum distance from y = 0 where mainsheet UI area is active [pixels]
    private let mainSheetMax: CGFloat = 400
    /// maximum distance from x = 0 where tiller UI area is active [pixels]
    private let tillerMax: CGFloat = 300 /// poop
    
    // SKNodes
    private var windLabel : SKLabelNode?
    private var speedLabel, leewardLabel : SKLabelNode?
    private var frLabel, frlLabel, fhLabel : SKLabelNode?
    private var aaLabel, heelLabel : SKLabelNode?
    private var lLabel, dLabel : SKLabelNode?
    private var sternNode : SKSpriteNode?
    
    // User input trackers
    /// latest commanded position of tiller from -1 (full left turn) to 1 (full right turn) []
    private var tillerPosition: CGFloat = 0
    /// latest commanded position of mainsheet from 0 (sheeted in) to 1 (sheeted out) []
    private var mainSheetPosition: CGFloat = 0
    
    
    // Initialization
    override func didMove(to view: SKView) {
        
        self.windLabel = self.childNode(withName: "//windLabel") as? SKLabelNode
        self.speedLabel = self.childNode(withName: "//speedLabel") as? SKLabelNode
        self.leewardLabel = self.childNode(withName: "//leewardLabel") as? SKLabelNode
        self.frLabel = self.childNode(withName: "//frLabel") as? SKLabelNode
        self.frlLabel = self.childNode(withName: "//frlLabel") as? SKLabelNode
        self.aaLabel = self.childNode(withName: "//aaLabel") as? SKLabelNode
        self.heelLabel = self.childNode(withName: "//heelLabel") as? SKLabelNode
        self.fhLabel = self.childNode(withName: "//fhLabel") as? SKLabelNode
        self.lLabel = self.childNode(withName: "//lLabel") as? SKLabelNode
        self.dLabel = self.childNode(withName: "//dLabel") as? SKLabelNode
        self.sternNode = self.childNode(withName: "//sternNode") as? SKSpriteNode
        
        self.sceneWidth = (self.scene?.size.width)!
        self.sceneHeight = (self.scene?.size.height)!
        
        createWater()
        
        boat.position = CGPoint(x: 75, y: 0)
        self.addChild(boat)
        
    }
    
    // UI creation
    func createWater() {
        for i in -2...2 {
            for j in -2...2 {
                let water = SKSpriteNode(imageNamed: "water")
                water.name = "water"
                water.size = CGSize(width: sceneWidth!+bgOverlap, height: sceneHeight!+bgOverlap)
                water.anchorPoint = CGPoint(x: 0.5+CGFloat(i), y: 0.5+CGFloat(j))
                water.position = CGPoint(x: 0, y: 0)
                water.zPosition = -1
                self.addChild(water)
            }
        }
    }
    
    
    // Frame Updates
    override func update(_ currentTime: TimeInterval) {
        /// boat movement this update [m]
        let boatMovement = boat.moveBoat(atTime: currentTime, wind: v_Tŵ, tillerPosition: tillerPosition, mainSheetPosition: mainSheetPosition)
        
        sceneShift -= boatMovement*GameViewController.pixelsPerMeter
        updateGraphics(boatMovement: boatMovement)
    }
    
    // UI updates
    func updateGraphics(boatMovement move: CGPoint) {
        if rotateBoatNotView {
            self.windLabel?.zRotation = v_Tŵ.θ
            self.boat.zRotation = self.boat.θ_Bŵ - CGFloat.pi/2 // NEED TO MAKE ABSOLUTELY CORRECT
        }
        else {
            self.windLabel?.zRotation = -self.boat.θ_Bŵ+v_Tŵ.θ+CGFloat.pi/2
            self.boat.zRotation = 0
        }
        
        self.sternNode?.zRotation = -self.boat.θ_bbŵ
        
        let nf: NumberFormatter = {
            let temporaryFormatter = NumberFormatter()
            temporaryFormatter.maximumFractionDigits = 1
            temporaryFormatter.minimumFractionDigits = 1
            temporaryFormatter.maximumIntegerDigits = 3
            temporaryFormatter.minimumIntegerDigits = 3
            return temporaryFormatter
        }()
        
        self.speedLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(self.boat.v_Bŵ.mag)*1.943))!) kts"
        self.leewardLabel?.text = "\(nf.string(from: NSNumber.init(value: Double((self.boat.v_Bŵ⋅v_Tŵ)/v_Tŵ.mag)*1.943))!) kts"
        self.frLabel?.text = "FR: \(nf.string(from: NSNumber.init(value: Double(self.boat.FR⋅self.boat.B̂)))!)"
        self.frlLabel?.text = "F.θ: \(nf.string(from: NSNumber.init(value: Double(self.boat.F.θ.rad2deg)))!)"
        self.aaLabel?.text = "α: \(nf.string(from: NSNumber.init(value: Double(self.boat.α.rad2deg)))!)"
        self.heelLabel?.text = "θ_bbŵ: \(nf.string(from: NSNumber.init(value: Double(self.boat.θ_bbŵ.rad2deg)))!)"
        self.fhLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(self.boat.Fh_sail.mag)))!)"
        self.lLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(self.boat.L_mainsailŵ.mag)))!)"
        self.dLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(self.boat.D_mainsailŵ.mag)))!)"
        
        
        while self.sceneShift.x < self.backgroundCenterRelativeToWorld.x - self.sceneWidth! { self.backgroundCenterRelativeToWorld.x -= self.sceneWidth! }
        while self.sceneShift.x > self.backgroundCenterRelativeToWorld.x + self.sceneWidth! { self.backgroundCenterRelativeToWorld.x += self.sceneWidth! }
        while self.sceneShift.y < self.backgroundCenterRelativeToWorld.y - self.sceneHeight! { self.backgroundCenterRelativeToWorld.y -= self.sceneHeight! }
        while self.sceneShift.y > self.backgroundCenterRelativeToWorld.y + self.sceneHeight! { self.backgroundCenterRelativeToWorld.y += self.sceneHeight! }
        
        self.enumerateChildNodes(withName: "water", using: ({
            (node, error) in
            node.position.x = self.sceneShift.x - self.backgroundCenterRelativeToWorld.x
            node.position.y = self.sceneShift.y - self.backgroundCenterRelativeToWorld.y
        }))
    }
    
    // touch helper methods.  Do I need all of these?
    func touchMoved(toPoint pos : CGPoint) {
        if pos.y < -640 { tillerUpdated(toValue: pos.x) }
        if pos.x < -270 && pos.y > -self.mainSheetMax { sheetUpdated(toValue: pos.y) }
   }
    
    func touchDown(atPoint pos : CGPoint) {  }
    func touchUp(atPoint pos : CGPoint) {  }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { for t in touches { self.touchDown(atPoint: t.location(in: self)) } }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { for t in touches { self.touchMoved(toPoint: t.location(in: self)) } }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { for t in touches { self.touchUp(atPoint: t.location(in: self)) } }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { for t in touches { self.touchUp(atPoint: t.location(in: self)) } }
    
    
    // UI event handling
    func tillerUpdated(toValue value: CGFloat) {
        if value > self.tillerMax { tillerPosition = 1 }
        else if value < -self.tillerMax { tillerPosition = -1 }
        else { tillerPosition = value/self.tillerMax }
    }
    
    func sheetUpdated(toValue value: CGFloat) {
        if value > self.mainSheetMax { mainSheetPosition = 1 }
        else if value < -self.mainSheetMax { mainSheetPosition = 0 }
        else { mainSheetPosition = (value + self.mainSheetMax)/self.mainSheetMax/2 }
    }
}

extension CGPoint {
    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x*right, y: left.y*right)
    }
    static func += (left: inout CGPoint, right: CGPoint) {
        left.x += right.x
        left.y += right.y
    }
    static func -= (left: inout CGPoint, right: CGPoint) {
        left.x -= right.x
        left.y -= right.y
    }
}
