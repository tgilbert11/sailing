//
//  GameScene.swift
//  sailing
//
//  Created by Taylor H. Gilbert on 6/24/17.
//  Copyright © 2017 Taylor H. Gilbert. All rights reserved.
//

import SpriteKit
import GameplayKit


class GameScene: SKScene {
    
    // Game Control
    private let rotateBoatNotView = true
    private let boat = Catalina_14p2()
    /// [m/s]
    private var v_Tŵ = CGVector3(x: 0, y: -6, z: 0)
    
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
    private var backgroundCenterRelativeToWorld = CGPoint.zero
    /// ratio of pixels per meter [pixels/m]
    private var pixelsPerMeter: CGFloat { get { return GameViewController.pixelsPerMeter } }
    
    // UI input things
    /// maximum distance from y = 0 where mainsheet UI area is active [pixels]
    private let mainSheetMax: CGFloat = 400
    /// maximum distance from x = 0 where tiller UI area is active [pixels]
    private let tillerMax: CGFloat = 300
    
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
        
        print(self.userData?.value(forKey: "ppm") as! CGFloat)
        
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
        
        self.boat.position = CGPoint(x: 75, y: 0)
        self.boat.xScale = self.pixelsPerMeter
        self.boat.yScale = self.pixelsPerMeter
        self.sceneShift = CGPoint(x: 5*GameViewController.pixelsPerMeter + 75, y: -5*GameViewController.pixelsPerMeter)
        self.addChild(boat)
        
        let objectsInWater = SKSpriteNode()
        objectsInWater.name = "objectsInWater"
        self.addChild(objectsInWater)
        
        let leftStartBuoy = SKSpriteNode(imageNamed: "buoy orange no lines")
        leftStartBuoy.position = CGPoint(x: 5*GameViewController.pixelsPerMeter, y: 10*GameViewController.pixelsPerMeter)
        leftStartBuoy.size = CGSize(width: 0.3*GameViewController.pixelsPerMeter, height: 1.2*GameViewController.pixelsPerMeter)
        leftStartBuoy.zPosition = 0.25
        objectsInWater.addChild(leftStartBuoy)
        
        let rightStartBuoy = SKSpriteNode(imageNamed: "buoy orange no lines")
        rightStartBuoy.position = CGPoint(x: 15*GameViewController.pixelsPerMeter, y: 10*GameViewController.pixelsPerMeter)
        rightStartBuoy.size = CGSize(width: 0.3*GameViewController.pixelsPerMeter, height: 1.2*GameViewController.pixelsPerMeter)
        rightStartBuoy.zPosition = 0.25
        objectsInWater.addChild(rightStartBuoy)
        
        let startArrow = SKSpriteNode(imageNamed: "start")
        startArrow.position = CGPoint(x: 8.33*GameViewController.pixelsPerMeter, y: 10*GameViewController.pixelsPerMeter)
        startArrow.size = CGSize(width: 3*GameViewController.pixelsPerMeter, height: 6*GameViewController.pixelsPerMeter)
        startArrow.alpha = 0.25
        objectsInWater.addChild(startArrow)
        
        let finishArrow = SKSpriteNode(imageNamed: "finish")
        finishArrow.position = CGPoint(x: 11.66*GameViewController.pixelsPerMeter, y: 10*GameViewController.pixelsPerMeter)
        finishArrow.size = CGSize(width: 3*GameViewController.pixelsPerMeter, height: 6*GameViewController.pixelsPerMeter)
        finishArrow.zRotation = 0
        finishArrow.alpha = 0.25
        objectsInWater.addChild(finishArrow)
        
        let windwardMark = SKSpriteNode(imageNamed: "buoy orange no lines")
        windwardMark.position = CGPoint(x: 10*GameViewController.pixelsPerMeter, y: 35*GameViewController.pixelsPerMeter)
        windwardMark.size = CGSize(width: 0.3*GameViewController.pixelsPerMeter, height: 1.2*GameViewController.pixelsPerMeter)
        windwardMark.zPosition = 0.25
        objectsInWater.addChild(windwardMark)
        
        let windwardApproachArrow = SKSpriteNode(imageNamed: "arrow blank up")
        windwardApproachArrow.position = CGPoint(x: 13*GameViewController.pixelsPerMeter, y: 35*GameViewController.pixelsPerMeter)
        windwardApproachArrow.size = CGSize(width: 3*GameViewController.pixelsPerMeter, height: 6*GameViewController.pixelsPerMeter)
        windwardApproachArrow.zRotation = 0
        windwardApproachArrow.alpha = 0.25
        objectsInWater.addChild(windwardApproachArrow)
        
        let windwardDepartureArrow = SKSpriteNode(imageNamed: "arrow blank up")
        windwardDepartureArrow.position = CGPoint(x: 7*GameViewController.pixelsPerMeter, y: 38*GameViewController.pixelsPerMeter)
        windwardDepartureArrow.size = CGSize(width: 3*GameViewController.pixelsPerMeter, height: 6*GameViewController.pixelsPerMeter)
        windwardDepartureArrow.zRotation = CGFloat.pi*3/4
        windwardDepartureArrow.alpha = 0.25
        objectsInWater.addChild(windwardDepartureArrow)
        
        let gybeMark = SKSpriteNode(imageNamed: "buoy orange no lines")
        gybeMark.position = CGPoint(x: -15*GameViewController.pixelsPerMeter, y: 10*GameViewController.pixelsPerMeter)
        gybeMark.size = CGSize(width: 0.3*GameViewController.pixelsPerMeter, height: 1.2*GameViewController.pixelsPerMeter)
        gybeMark.zPosition = 0.25
        objectsInWater.addChild(gybeMark)
        
        let gybeApproachArrow = SKSpriteNode(imageNamed: "arrow blank up")
        gybeApproachArrow.position = CGPoint(x: -18*GameViewController.pixelsPerMeter, y: 13*GameViewController.pixelsPerMeter)
        gybeApproachArrow.size = CGSize(width: 3*GameViewController.pixelsPerMeter, height: 6*GameViewController.pixelsPerMeter)
        gybeApproachArrow.zRotation = CGFloat.pi*3/4
        gybeApproachArrow.alpha = 0.25
        objectsInWater.addChild(gybeApproachArrow)
        
        let gybeDepartureArrow = SKSpriteNode(imageNamed: "arrow blank up")
        gybeDepartureArrow.position = CGPoint(x: -18*GameViewController.pixelsPerMeter, y: 7*GameViewController.pixelsPerMeter)
        gybeDepartureArrow.size = CGSize(width: 3*GameViewController.pixelsPerMeter, height: 6*GameViewController.pixelsPerMeter)
        gybeDepartureArrow.zRotation = CGFloat.pi*5/4
        gybeDepartureArrow.alpha = 0.25
        objectsInWater.addChild(gybeDepartureArrow)
        
        let leewardMark = SKSpriteNode(imageNamed: "buoy orange no lines")
        leewardMark.position = CGPoint(x: 10*GameViewController.pixelsPerMeter, y: -15*GameViewController.pixelsPerMeter)
        leewardMark.size = CGSize(width: 0.3*GameViewController.pixelsPerMeter, height: 1.2*GameViewController.pixelsPerMeter)
        leewardMark.zPosition = 0.25
        objectsInWater.addChild(leewardMark)
        
        let leewardApproachArrow = SKSpriteNode(imageNamed: "arrow blank up")
        leewardApproachArrow.position = CGPoint(x: 7*GameViewController.pixelsPerMeter, y: -18*GameViewController.pixelsPerMeter)
        leewardApproachArrow.size = CGSize(width: 3*GameViewController.pixelsPerMeter, height: 6*GameViewController.pixelsPerMeter)
        leewardApproachArrow.zRotation = CGFloat.pi*5/4
        leewardApproachArrow.alpha = 0.25
        objectsInWater.addChild(leewardApproachArrow)
        
        let leewardDepartureArrow = SKSpriteNode(imageNamed: "arrow blank up")
        leewardDepartureArrow.position = CGPoint(x: 13*GameViewController.pixelsPerMeter, y: -15*GameViewController.pixelsPerMeter)
        leewardDepartureArrow.size = CGSize(width: 3*GameViewController.pixelsPerMeter, height: 6*GameViewController.pixelsPerMeter)
        leewardDepartureArrow.zRotation = 0
        leewardDepartureArrow.alpha = 0.25
        objectsInWater.addChild(leewardDepartureArrow)
        
        
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
        boat.moveBoat(atTime: currentTime, wind: v_Tŵ, tillerPosition: tillerPosition, mainSheetPosition: mainSheetPosition)
        print(boat.statusString())
        //sceneShift -= boatMovement*GameViewController.pixelsPerMeter
        updateGraphics()
    }
    
    // UI updates
    func updateGraphics() {
        if rotateBoatNotView {
            self.windLabel?.zRotation = v_Tŵ.θz
            self.boat.zRotation = self.boat.x_Bŵ.θz - CGFloat.pi/2 // NEED TO MAKE ABSOLUTELY CORRECT
        }
        else {
            self.windLabel?.zRotation = -self.boat.x_Bŵ.θz+v_Tŵ.θz+CGFloat.pi/2
            self.boat.zRotation = 0
        }
        
        self.sternNode?.zRotation = -self.boat.x_Bŵ.θx
        
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
        self.frLabel?.text = "FR: \(nf.string(from: NSNumber.init(value: Double(0)))!)"
        self.frlLabel?.text = "F.θ: \(nf.string(from: NSNumber.init(value: Double(self.boat.F_mainsail.θz.rad2deg)))!)"
        self.aaLabel?.text = "α: \(nf.string(from: NSNumber.init(value: Double(self.boat.α.rad2deg)))!)"
        self.heelLabel?.text = "θ_bbŵ: \(nf.string(from: NSNumber.init(value: Double(self.boat.x_Bŵ.θx.rad2deg)))!)"
        self.fhLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(0)))!)"
        self.lLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(0)))!)"
        self.dLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(0)))!)"
        
        
        while self.sceneShift.x < self.backgroundCenterRelativeToWorld.x - self.sceneWidth! { self.backgroundCenterRelativeToWorld.x -= self.sceneWidth! }
        while self.sceneShift.x > self.backgroundCenterRelativeToWorld.x + self.sceneWidth! { self.backgroundCenterRelativeToWorld.x += self.sceneWidth! }
        while self.sceneShift.y < self.backgroundCenterRelativeToWorld.y - self.sceneHeight! { self.backgroundCenterRelativeToWorld.y -= self.sceneHeight! }
        while self.sceneShift.y > self.backgroundCenterRelativeToWorld.y + self.sceneHeight! { self.backgroundCenterRelativeToWorld.y += self.sceneHeight! }
        
        self.enumerateChildNodes(withName: "water", using: ({
            (node, error) in
            node.position.x = self.sceneShift.x - self.backgroundCenterRelativeToWorld.x
            node.position.y = self.sceneShift.y - self.backgroundCenterRelativeToWorld.y
        }))
        self.enumerateChildNodes(withName: "objectsInWater", using: ({
            (node, error) in
            node.position.x = self.sceneShift.x
            node.position.y = self.sceneShift.y
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


