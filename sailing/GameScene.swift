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
    
    // world = ŵ
    // boat = B̂
    //    lat = l̂
    // V_Aŵ = â
    // sail = ŝ
    
    // sail forces act in â
    // hull forces act in b̂ (boat right/lat is l̂)
    // position and velocity are in ŵ
    
    // Game Control
    private let rotateBoatNotView = true
    private let boat = Catalina_142.init()
    private var v_Tŵ = CGVector(dx: 0, dy: 6) // m/s
    
    // simulation information
    private var lastSceneUpdateTime: TimeInterval = 0 // s
    private var firstUpdate = true
    private var pixelsPerMeter: CGFloat = 1080/30*10 // pixels/m
    private var bgOverlap: CGFloat = 5 // pixels
    
    // Debugging
    private var debugStrings = [String]()
    
    // SKNodes
    private var boatLabel : SKLabelNode?
    private var sailLabel : SKLabelNode?
    private var windLabel : SKLabelNode?
    private var wobLabel : SKLabelNode?
    private var speedLabel : SKLabelNode?
    private var leewardLabel : SKLabelNode?
    private var frLabel : SKLabelNode?
    private var frlLabel : SKLabelNode?
    private var aaLabel : SKLabelNode?
    private var heelLabel : SKLabelNode?
    private var fhLabel : SKLabelNode?
    private var lLabel : SKLabelNode?
    private var dLabel : SKLabelNode?
    private var sternNode : SKSpriteNode?
    private var topSailNode : SKSpriteNode?
    private var topForcesNode : SKSpriteNode?
    
    
    // User input trackers
    private var tillerPosition: CGFloat = 0 // [], [-1,1]
    private var mainSheetPosition: CGFloat = 0 // [], [0,1]
    
    // Constants
    // ----- ----- -----
    
    
    // Initialization
    override func didMove(to view: SKView) {
        
        self.boatLabel = self.childNode(withName: "//boatLabel") as? SKLabelNode
        self.sailLabel = self.childNode(withName: "//sailLabel") as? SKLabelNode
        self.windLabel = self.childNode(withName: "//windLabel") as? SKLabelNode
        self.wobLabel = self.childNode(withName: "//wobLabel") as? SKLabelNode
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
        self.topSailNode = self.childNode(withName: "//topSail") as? SKSpriteNode
        self.topForcesNode = self.childNode(withName: "//topForces") as? SKSpriteNode
        
        createWater()
        
    }
    
    // Frame Updates
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        boat.calculateFrame(atTime: currentTime, wind: v_Tŵ, tillerPosition: tillerPosition, mainSheetPosition: mainSheetPosition)
        
        debugStrings.append(" === SIMULATION ===")
        debugStrings.append("time: \(currentTime)")
        
        //printCalculations()
        
        updateGraphics()
        
        debugStrings.append(self.boat.statusString())
        
        var finalString = ""
        for debugString in debugStrings {
            finalString = finalString + debugString + "\n"
        }
        print(finalString)
        debugStrings.removeAll()
    }
    
    // UI updates
    func updateGraphics() {
        if rotateBoatNotView {
            self.windLabel?.zRotation = v_Tŵ.θ
            self.boatLabel?.zRotation = self.boat.θ_Bŵ
        }
        else {
            self.windLabel?.zRotation = -self.boat.θ_Bŵ+v_Tŵ.θ+CGFloat.pi/2
            self.boatLabel?.zRotation = CGFloat.pi/2
        }
        
        self.sternNode?.zRotation = -self.boat.θ_bbŵ
        self.topSailNode?.zRotation = self.boat.θ_sB̂+CGFloat.pi
        self.topForcesNode?.zRotation = self.boat.V_AB̂.θ+CGFloat.pi
        
        let nf: NumberFormatter = {
            let temporaryFormatter = NumberFormatter()
            temporaryFormatter.maximumFractionDigits = 1
            temporaryFormatter.minimumFractionDigits = 1
            temporaryFormatter.maximumIntegerDigits = 3
            temporaryFormatter.minimumIntegerDigits = 3
            return temporaryFormatter
        }()
        
        
        
        self.sailLabel?.zRotation = self.boat.θ_sB̂
        self.wobLabel?.zRotation = self.boat.V_AB̂.θ
        self.speedLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(self.boat.v_Bŵ.mag)*1.943))!) kts"
        self.leewardLabel?.text = "\(nf.string(from: NSNumber.init(value: Double((self.boat.v_Bŵ⋅v_Tŵ)/v_Tŵ.mag)*1.943))!) kts"
        self.frLabel?.text = "FR: \(nf.string(from: NSNumber.init(value: Double(self.boat.FR⋅self.boat.B̂)))!)"
        self.frlLabel?.text = "F.θ: \(nf.string(from: NSNumber.init(value: Double(self.boat.F.θ.rad2deg)))!)"
        self.aaLabel?.text = "α: \(nf.string(from: NSNumber.init(value: Double(self.boat.α.rad2deg)))!)"
        self.heelLabel?.text = "θ_bbŵ: \(nf.string(from: NSNumber.init(value: Double(self.boat.θ_bbŵ.rad2deg)))!)"
        self.fhLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(self.boat.Fh_sail.mag)))!)"
        self.lLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(self.boat.L_mainsailŵ.mag)))!)"
        self.dLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(self.boat.D_mainsailŵ.mag)))!)"
        //self.water?.position.x -= Δx_Bŵ.dx*pixelsPerMeter
        //self.water?.position.y -= Δx_Bŵ.dy*pixelsPerMeter
        updateWater()
    }
    
    func updateWater() {
        self.enumerateChildNodes(withName: "water", using: ({
            (node, error) in
            node.position.x -= self.boat.Δx_Bŵ.dx*self.pixelsPerMeter
            node.position.y -= self.boat.Δx_Bŵ.dy*self.pixelsPerMeter
            
            if node.position.x < -(self.scene?.size.width)!*2.5 { node.position.x += (self.scene?.size.width)!*5 }
            if node.position.x > (self.scene?.size.width)!*1.5 { node.position.x -= (self.scene?.size.width)!*5 }
            if node.position.y < -(self.scene?.size.height)!*2.5 { node.position.y += (self.scene?.size.height)!*5 }
            if node.position.y > (self.scene?.size.height)!*1.5 { node.position.y -= (self.scene?.size.height)!*5 }
        }))
    }
    
    // UI event handling
    func tillerUpdated(toValue value: CGFloat) {
        if value > self.boat.tillerMax { tillerPosition = 1 }
        else if value < -self.boat.tillerMax { tillerPosition = -1 }
        else { tillerPosition = value/self.boat.tillerMax }
    }
    
    func sheetUpdated(toValue value: CGFloat) {
        if value > self.boat.mainSheetMax { mainSheetPosition = 1 }
        else if value < -self.boat.mainSheetMax { mainSheetPosition = 0 }
        else { mainSheetPosition = (value + self.boat.mainSheetMax)/self.boat.mainSheetMax/2 }
        //print("main sheet at \(mainSheetPosition)")
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if pos.y < -640 { tillerUpdated(toValue: pos.x) }
        if pos.x < -270 && pos.y > -self.boat.mainSheetMax { sheetUpdated(toValue: pos.y) }
   }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    // build the UI
    func createWater() {
        let sceneWidth = (self.scene?.size.width)!
        let sceneHeight = (self.scene?.size.height)!
        for i in -2...2 {
            for j in -2...2 {
                let water = SKSpriteNode(imageNamed: "water")
                water.name = "water"
                water.size = CGSize(width: sceneWidth+2*bgOverlap, height: sceneHeight+2*bgOverlap)
                water.anchorPoint = CGPoint(x: 0, y: 0)
                water.position = CGPoint(x: sceneWidth*CGFloat(i)-sceneWidth/2, y: sceneHeight*CGFloat(j)-sceneHeight/2)
                water.zPosition = -1
                
                self.addChild(water)
            }
        }
    }
    
}


