//
//  GameScene.swift
//  sailing
//
//  Created by Taylor H. Gilbert on 6/24/17.
//  Copyright © 2017 Taylor H. Gilbert. All rights reserved.
//

import SpriteKit
import GameplayKit

infix operator ⋅

class GameScene: SKScene {
    
    // Game Control
    private let rotateBoatNotView = true
    private var VT = CGVector(dx: 0, dy: 5)
    private var XB = CGVector(dx: 0, dy: 0)
    private var delta_XB = CGVector(dx: 0, dy: 0)
    private var VB = CGVector(dx: 0, dy: 0)
    private var B: CGFloat = 0*CGFloat.pi/2
    
    // simulation information
    private var lastSceneUpdateTime: TimeInterval = 0
    private var firstUpdate = true
    private var pixelsPerMeter: CGFloat = 1080/30
    private var bgOverlap: CGFloat = 5
    
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
    private var heelLabel : SKLabelNode?
    
    
    // User input trackers
    private var tillerPosition: CGFloat = 0 // [-1,1]
    private var mainSheetPosition: CGFloat = 0 // [0,1]
    
    
    // Constants
    private let ρ_air: CGFloat = 1.225
    private let ρ_water: CGFloat = 1000
    
    private let tillerMax: CGFloat = 300
    
    private let mainSheetClosestHaul: CGFloat = 0.25
    private let mainSheetMax: CGFloat = 400
    private let mainSailMaxAngle: CGFloat = 1.22
    
    private let boatHeadingChangePerTillerKtSecond: CGFloat = 0.25
    private let A_mainsail: CGFloat = 6.81
    private let M_boat: CGFloat = 250
    private let S_boat: CGFloat = 7
    private let CD_hull_R: CGFloat = 0.004 // 0.011
    private let CD_hull_LAT: CGFloat = 0.4
    
    // Computed Properties
    private var LAT: CGFloat { get { return B + CGFloat.pi*3/2 } }
    private var B_hat: CGVector { get { return CGVector.init(normalWithAngle: B) } }
    private var LAT_hat: CGVector { get { return CGVector.init(normalWithAngle: LAT) } }
    private var VA: CGVector { get { return VT - VB } }
    private var VA_B: CGVector { get { return VA.rotatedBy(radians: -B) } }
    
    private var α: CGFloat { get { return abs(VA_B.θ-s_B) } }
    private var L_mainsail: CGVector { get { return
        VA.rotatedBy(radians: CGFloat.pi/2*(VA_B.θ > CGFloat.pi ? 1 : -1)).normalized() * 0.5 * ρ_air * VA.mag2 * A_mainsail * CL_mainsail } }
    private var D_mainsail: CGVector { get { return VA/VA.mag * 0.5 * ρ_air * VA.mag2 * A_mainsail * CD_mainsail } }
    private var D_hull: CGVector { get { return
        B_hat * -0.5 * ρ_water * (VB⋅B_hat) * abs(VB⋅B_hat) * S_boat * CD_hull_R
        - LAT_hat * 0.5 * ρ_water * (VB⋅LAT_hat) * abs(VB⋅LAT_hat) * S_boat * CD_hull_LAT } }
    
    private var FR: CGVector { get { return B_hat*(B_hat⋅L_mainsail) + B_hat*(B_hat⋅D_mainsail) + B_hat*(B_hat⋅D_hull) } }
    private var FLAT: CGVector { get { return LAT_hat*(LAT_hat⋅L_mainsail) + LAT_hat*(LAT_hat⋅D_mainsail) + LAT_hat*(LAT_hat⋅D_hull) } }
    
    
    // try to make this absolute value, rather than conditional
    private var s_B: CGFloat { get {
        if VA_B.θ < CGFloat.pi - mainSheetClosestHaul - (mainSailMaxAngle - mainSheetClosestHaul)*mainSheetPosition {
            return CGFloat.pi - (mainSheetClosestHaul + (mainSailMaxAngle-mainSheetClosestHaul)*mainSheetPosition)
        }
        else if VA_B.θ > CGFloat.pi + mainSheetClosestHaul + (mainSailMaxAngle-mainSheetClosestHaul)*mainSheetPosition {
            return CGFloat.pi + mainSheetClosestHaul + (mainSailMaxAngle-mainSheetClosestHaul)*mainSheetPosition
        }
        else {
            return VA_B.θ
        }
    }}
    
    private var s_Bb: CGFloat { get {
        if VA_B.θ < CGFloat.pi - mainSheetClosestHaul - (mainSailMaxAngle - mainSheetClosestHaul)*mainSheetPosition {
            return CGFloat.pi - (mainSheetClosestHaul + (mainSailMaxAngle-mainSheetClosestHaul)*mainSheetPosition)
        }
        else if VA_B.θ > CGFloat.pi + mainSheetClosestHaul + (mainSailMaxAngle-mainSheetClosestHaul)*mainSheetPosition {
            return CGFloat.pi + mainSheetClosestHaul + (mainSailMaxAngle-mainSheetClosestHaul)*mainSheetPosition
        }
        else {
            return VA_B.θ
        }
    }}
    
    private var CL_mainsail: CGFloat { get {
        switch α {
        case 0 ..< CGFloat(10).deg2rad:
            return 0
        case CGFloat(10).deg2rad ..< CGFloat(20).deg2rad:
            return 0 + 1.2*(α-CGFloat(10).deg2rad)/CGFloat(10).deg2rad
        case CGFloat(20).deg2rad ..< CGFloat(30).deg2rad:
            return 1.2 + 0.4*(α-CGFloat(20).deg2rad)/CGFloat(10).deg2rad
        case CGFloat(30).deg2rad ..< CGFloat(50).deg2rad:
            return 1.6 - 0.2*(α-CGFloat(30).deg2rad)/CGFloat(20).deg2rad
        case CGFloat(50).deg2rad ..< CGFloat(100).deg2rad:
            return 1.4 - 1.4*(α-CGFloat(50).deg2rad)/CGFloat(50).deg2rad
        default:
            return 0
        }
    }}
    
    private var CD_mainsail: CGFloat { get {
        if α > CGFloat(100).deg2rad {
            return 1.6
        }
        else {
            return 0.2 + 1.4*pow(α/CGFloat(100).deg2rad,2)
        }
    }}
    
    
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
        self.heelLabel = self.childNode(withName: "//heelLabel") as? SKLabelNode
        
        createWater()
    }
    
    // Frame Updates
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if firstUpdate == true {
            lastSceneUpdateTime = currentTime
            firstUpdate = false
        }
        let timeSinceLastScene = currentTime - lastSceneUpdateTime
        lastSceneUpdateTime = currentTime
        debugStrings.append(" === SIMULATION ===")
        debugStrings.append("time: \(timeSinceLastScene)")
        
        
        printCalculations()
        
        delta_XB = VB * CGFloat(timeSinceLastScene)
        XB = XB + delta_XB
        VB = VB + (FR+FLAT)/M_boat*CGFloat(timeSinceLastScene)
        
        let boatRotation = boatHeadingChangePerTillerKtSecond*tillerPosition*(VB⋅B_hat)*CGFloat(timeSinceLastScene)
        VB = VB.rotatedBy(radians: boatRotation)
        B = B + boatRotation
        
        
        debugStrings.append("   B:  \(B.rad2deg)")
        debugStrings.append("  VB: \(VB)")
        
        updateGraphics()
        
        var finalString = ""
        for debugString in debugStrings {
            finalString = finalString + debugString + "\n"
        }
        print(finalString)
        debugStrings.removeAll()
    }
    
    // Printing
    func printCalculations() {
        debugStrings.append("  VT: \(VT)")
        debugStrings.append("  XB: (\(XB.dx), \(XB.dy))")
        debugStrings.append("   B: \(B.rad2deg)")
        debugStrings.append("  VB: \(VB)")
        debugStrings.append("  VA: \(VA)")
        debugStrings.append("VA_B: \(VA_B)")
        debugStrings.append(" s_B: \(s_B.rad2deg)")
        debugStrings.append("s_Bb: \(s_Bb.rad2deg)")
        debugStrings.append("   α: \(α.rad2deg)")
        debugStrings.append("CL_m: \(CL_mainsail)")
        debugStrings.append("CD_m: \(CD_mainsail)")
        debugStrings.append(" L_m: \(L_mainsail)")
        debugStrings.append(" D_m: \(D_mainsail)")
        debugStrings.append("tack: \(VA_B.θ > CGFloat.pi ? "port" : "starboard")")
        debugStrings.append(" D_h: \(D_hull)")
        debugStrings.append("  FR: \(FR)")
        debugStrings.append("FLAT: \(FLAT)")
    }
    
    // UI updates
    func updateGraphics() {
        if rotateBoatNotView {
            self.windLabel?.zRotation = VT.θ
            self.boatLabel?.zRotation = B
        }
        else {
            self.windLabel?.zRotation = -B+VT.θ+CGFloat.pi/2
            self.boatLabel?.zRotation = CGFloat.pi/2
        }
        
        let nf: NumberFormatter = {
            let temporaryFormatter = NumberFormatter()
            temporaryFormatter.maximumFractionDigits = 1
            temporaryFormatter.minimumFractionDigits = 1
            temporaryFormatter.maximumIntegerDigits = 3
            temporaryFormatter.minimumIntegerDigits = 3
            return temporaryFormatter
        }()
        
        self.sailLabel?.zRotation = s_B
        self.wobLabel?.zRotation = VA_B.θ
        self.speedLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(VB⋅B_hat)*1.943))!) kts"
        self.leewardLabel?.text = "\(nf.string(from: NSNumber.init(value: Double((VB⋅VT)/VT.mag)*1.943))!) kts"
        self.frLabel?.text = "FR: \(nf.string(from: NSNumber.init(value: Double(FR⋅B_hat)))!)"
        self.frlLabel?.text = "FRL: \(nf.string(from: NSNumber.init(value: Double((FR⋅VT)/VT.mag)))!)"
        self.heelLabel?.text = "α: \(nf.string(from: NSNumber.init(value: Double(α.rad2deg)))!)"
        //self.water?.position.x -= delta_XB.dx*pixelsPerMeter
        //self.water?.position.y -= delta_XB.dy*pixelsPerMeter
        updateWater()
    }
    
    func updateWater() {
        self.enumerateChildNodes(withName: "water", using: ({
            (node, error) in
            node.position.x -= self.delta_XB.dx*self.pixelsPerMeter
            node.position.y -= self.delta_XB.dy*self.pixelsPerMeter
            
            if node.position.x < -(self.scene?.size.width)!*2.5 { node.position.x += (self.scene?.size.width)!*5 }
            else if node.position.x > (self.scene?.size.width)!*1.5 { node.position.x -= (self.scene?.size.width)!*5 }
            else if node.position.y < -(self.scene?.size.height)!*2.5 { node.position.y += (self.scene?.size.height)!*5 }
            else if node.position.y > (self.scene?.size.height)!*1.5 { node.position.y += (self.scene?.size.height)!*5 }
        }))
    }
    
    // UI event handling
    func tillerUpdated(toValue value: CGFloat) {
        if value > tillerMax { tillerPosition = 1 }
        else if value < -tillerMax { tillerPosition = -1 }
        else { tillerPosition = value/tillerMax }
    }
    
    func sheetUpdated(toValue value: CGFloat) {
        if value > mainSheetMax { mainSheetPosition = 1 }
        else if value < -mainSheetMax { mainSheetPosition = 0 }
        else { mainSheetPosition = (value + mainSheetMax)/mainSheetMax/2 }
        //print("main sheet at \(mainSheetPosition)")
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if pos.y < -640 { tillerUpdated(toValue: pos.x) }
        if pos.x < -270 { sheetUpdated(toValue: pos.y) }
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

// Extensions

extension CGFloat {
    func normalizedAngle() -> CGFloat {
        var modifiedAngle = self
        while modifiedAngle < 0 { modifiedAngle = modifiedAngle + 2*CGFloat.pi }
        while modifiedAngle >= 2*CGFloat.pi { modifiedAngle = modifiedAngle - 2*CGFloat.pi }
        return modifiedAngle
    }
    var deg2rad: CGFloat { return self * CGFloat.pi / 180 }
    var rad2deg: CGFloat { return self * 180 / CGFloat.pi }
}

extension CGVector: CustomStringConvertible {
    var θ: CGFloat { return CGFloat(atan2(self.dy, self.dx)).normalizedAngle()}
    var mag: CGFloat { return pow(pow(self.dx,2)+pow(self.dy,2),1/2) }
    var mag2: CGFloat { return pow(self.dx,2)+pow(self.dy,2) }
    
    init(normalWithAngle θ: CGFloat) {
        self.init(dx: cos(θ), dy: sin(θ))
    }
    
    public var description: String {
        let nf = NumberFormatter()
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2
        nf.minimumIntegerDigits = 3
        nf.string(from: NSNumber(value: Double(self.mag)))
        return "(mag: \(nf.string(from: NSNumber(value: Double(self.mag)))!), θ: \(nf.string(from: NSNumber(value: Double(self.θ.rad2deg)))!))"
        //return "(\(self.dx), \(self.dy)); (mag: \(self.mag), θ: \(self.θ))"
    }
    
    func rotatedBy(radians θ: CGFloat) -> CGVector {
        return CGVector(dx: self.dx*cos(θ)-self.dy*sin(θ), dy: self.dx*sin(θ)+self.dy*cos(θ))
    }
    func normalized() -> CGVector {
        return self/self.mag
    }
    static func + (left: CGVector, right: CGVector) -> CGVector {
        return CGVector(dx: left.dx+right.dx, dy: left.dy+right.dy)
    }
    static func - (left: CGVector, right: CGVector) -> CGVector {
        return CGVector(dx: left.dx-right.dx, dy: left.dy-right.dy)
    }
    static func * (left: CGVector, right: CGFloat) -> CGVector {
        return CGVector(dx: left.dx*right, dy: left.dy*right)
    }
    static func * (left: CGFloat, right: CGVector) -> CGVector {
        return CGVector(dx: left*right.dx, dy: left*right.dy)
    }
    static func / (left: CGVector, right: CGFloat) -> CGVector {
        return CGVector(dx: left.dx/right, dy: left.dy/right)
    }
    static func ⋅ (left: CGVector, right: CGVector) -> CGFloat {
        return left.dx * right.dx + left.dy * right.dy
    }
    
}
