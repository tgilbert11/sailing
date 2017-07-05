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
    private var v_Tŵ = CGVector(dx: 0, dy: 6) // m/s
    private var x_Bŵ = CGVector(dx: 0, dy: 0) // m
    private var Δx_Bŵ = CGVector(dx: 0, dy: 0) // Δm/s
    private var v_Bŵ = CGVector(dx: 0, dy: 0) // m/s
    private var θ_Bŵ: CGFloat = -0.5*CGFloat.pi/2*0 // radians
    private var θ_bbŵ: CGFloat = 0 // radians
    private var Δθ_bbŵ: CGFloat = 0 // Δradians
    
    // simulation information
    private var lastSceneUpdateTime: TimeInterval = 0 // s
    private var firstUpdate = true
    private var pixelsPerMeter: CGFloat = 1080/30 // pixels/m
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
    private let g: CGFloat = 9.806 // m/s2
    private let ρ_air: CGFloat = 1.225 // kg/m3
    private let ρ_water: CGFloat = 1000 // kg/m3
    
    private let tillerMax: CGFloat = 300 // pixels
    
    private let mainSheetClosestHaul: CGFloat = 0.25 // radians
    private let mainSheetMax: CGFloat = 400 // pixels
    private let mainSailMaxAngle: CGFloat = 1.22 // radians
    
    private let boatHeadingChangePerTillerKtSecond: CGFloat = 0.25 // radians/([]*m/s*s)
    private let A_mainsail: CGFloat = 6.81 // m2
    private let M_boat: CGFloat = 250 // kg
    private let S_boat: CGFloat = 7 // m2
    private let CD_hull_R: CGFloat = 0.005 // [], 0.011 by lookup
    private let CD_hull_LAT: CGFloat = 0.4 // []
    private let h_mainsail: CGFloat = 2.75 // m, height of force application on mainsail
    private let c: CGFloat = 0.4 // m, depth of force application below CG
    private let I_bb: CGFloat = 500 // kg*m2, NEED TO REFINE
    
    // Computed Properties
    private var θ_lB̂: CGFloat { get { return CGFloat.pi/2 + (V_AB̂.θ < CGFloat.pi ? CGFloat.pi : 0) } }
    private var θ_lŵ: CGFloat { get { return θ_lB̂ + θ_Bŵ } } // radians
    private var B̂: CGVector { get { return CGVector.init(normalWithAngle: θ_Bŵ) } } // []
    private var l̂: CGVector { get { return CGVector.init(normalWithAngle: θ_lŵ) } } // []
    private var V_Aŵ: CGVector { get { return v_Tŵ - v_Bŵ } } // m/s
    private var V_AB̂: CGVector { get { return V_Aŵ.rotatedBy(radians: -θ_Bŵ) } } // m/s
    
    private var α: CGFloat { get { return abs(V_AB̂.θ-θ_sB̂) } } // radians
    private var L_mainsailŵ: CGVector { get { return V_Aŵ.rotatedBy(radians: θ_lB̂).normalized() * 0.5 * ρ_air * V_Aŵ.mag2 * A_mainsail * cos(θ_bbŵ) * CL_mainsail } } // N
    private var D_mainsailŵ: CGVector { get { return V_Aŵ/V_Aŵ.mag * 0.5 * ρ_air * V_Aŵ.mag2 * A_mainsail * cos(θ_bbŵ) * CD_mainsail } } // N
    private var D_hullŵ: CGVector { get { return
        B̂ * -0.5 * ρ_water * (v_Bŵ⋅B̂) * abs(v_Bŵ⋅B̂) * S_boat * CD_hull_R
        - l̂ * 0.5 * ρ_water * (v_Bŵ⋅l̂) * abs(v_Bŵ⋅l̂) * S_boat * cos(θ_bbŵ) * CD_hull_LAT } } // N
    
    private var FR: CGVector { get { return L_mainsailŵ⊙B̂ + D_mainsailŵ⊙B̂ + D_hullŵ⊙B̂ } } // N
    private var Fh_sail: CGVector { get { return L_mainsailŵ⊙l̂ + D_mainsailŵ⊙l̂ } } // N
    private var Fh_hull: CGVector { get { return D_hullŵ⊙l̂ } } // N
    private var FLAT: CGVector { get { return Fh_sail + Fh_hull } } // N
    private var F: CGVector { get { return FR + FLAT } }
    
    private var τ_bb: CGFloat { get { return Fh_hull.mag*c + Fh_sail.mag*h_mainsail - M_boat*g*b } } // Nm
    private var b: CGFloat { get { return 0.4*sin(2.4*θ_bbŵ) } } // m
    
    
    // try to make this absolute value, rather than conditional
    private var θ_sB̂: CGFloat { get {
        if V_AB̂.θ < CGFloat.pi - mainSheetClosestHaul - (mainSailMaxAngle - mainSheetClosestHaul)*mainSheetPosition {
            return CGFloat.pi - (mainSheetClosestHaul + (mainSailMaxAngle - mainSheetClosestHaul)*mainSheetPosition)
        }
        else if V_AB̂.θ > CGFloat.pi + mainSheetClosestHaul + (mainSailMaxAngle-mainSheetClosestHaul)*mainSheetPosition {
            return CGFloat.pi + mainSheetClosestHaul + (mainSailMaxAngle-mainSheetClosestHaul)*mainSheetPosition
        }
        else {
            return V_AB̂.θ
        }
    }}
    
//    private var CL_mainsail: CGFloat { get {
//        switch α {
//        case 0 ..< CGFloat(10).deg2rad:
//            return 0
//        case CGFloat(10).deg2rad ..< CGFloat(20).deg2rad:
//            return 0 + 1.2*(α-CGFloat(10).deg2rad)/CGFloat(10).deg2rad
//        case CGFloat(20).deg2rad ..< CGFloat(30).deg2rad:
//            return 1.2 + 0.4*(α-CGFloat(20).deg2rad)/CGFloat(10).deg2rad
//        case CGFloat(30).deg2rad ..< CGFloat(50).deg2rad:
//            return 1.6 - 0.2*(α-CGFloat(30).deg2rad)/CGFloat(20).deg2rad
//        case CGFloat(50).deg2rad ..< CGFloat(100).deg2rad:
//            return 1.4 - 1.4*(α-CGFloat(50).deg2rad)/CGFloat(50).deg2rad
//        default:
//            return 0
//        }
//        }}
    
    private var CL_mainsail: CGFloat { get {
        switch α {
        case 0 ..< CGFloat(10).deg2rad:
            return 0
        case CGFloat(10).deg2rad ..< CGFloat(20).deg2rad:
            return 0 + 1.2*(α-CGFloat(10).deg2rad)/CGFloat(10).deg2rad
        case CGFloat(20).deg2rad ..< CGFloat(30).deg2rad:
            return 1.2 + 0.4*(α-CGFloat(20).deg2rad)/CGFloat(10).deg2rad
        case CGFloat(30).deg2rad ..< CGFloat(50).deg2rad:
            return 1.6 - 1.2*(α-CGFloat(30).deg2rad)/CGFloat(20).deg2rad
        case CGFloat(50).deg2rad ..< CGFloat(100).deg2rad:
            return 0.4 - 0.4*(α-CGFloat(50).deg2rad)/CGFloat(50).deg2rad
        default:
            return 0
        }
        }}
    
    private var CD_mainsail: CGFloat { get {
        if α > CGFloat(50).deg2rad {
            return 1.6
        }
        else {
            return 0.2 + 1.4*pow(α/CGFloat(50).deg2rad,2)
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
        if firstUpdate == true {
            lastSceneUpdateTime = currentTime
            firstUpdate = false
        }
        let timeSinceLastScene = currentTime - lastSceneUpdateTime
        lastSceneUpdateTime = currentTime
        debugStrings.append(" === SIMULATION ===")
        debugStrings.append("time: \(timeSinceLastScene)")
        
        
        printCalculations()
        
        Δx_Bŵ = v_Bŵ * CGFloat(timeSinceLastScene)
        x_Bŵ = x_Bŵ + Δx_Bŵ
        v_Bŵ = v_Bŵ + (FR+FLAT)/M_boat*CGFloat(timeSinceLastScene)
            
        Δθ_bbŵ = τ_bb / I_bb * CGFloat(timeSinceLastScene)
        θ_bbŵ = θ_bbŵ + Δθ_bbŵ
        if θ_bbŵ > CGFloat.pi/2 { θ_bbŵ = 0 }
        
        let boatRotation = boatHeadingChangePerTillerKtSecond*tillerPosition*(v_Bŵ⋅B̂)*CGFloat(timeSinceLastScene)
        v_Bŵ = v_Bŵ.rotatedBy(radians: boatRotation)
        θ_Bŵ = θ_Bŵ + boatRotation
        
        
        debugStrings.append(" θ_Bŵ:  \(θ_Bŵ.rad2deg)")
        debugStrings.append(" v_Bŵ: \(v_Bŵ)")
        
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
        debugStrings.append(" v_Tŵ: \(v_Tŵ)")
        debugStrings.append(" x_Bŵ: (\(x_Bŵ.dx), \(x_Bŵ.dy))")
        debugStrings.append(" θ_Bŵ: \(θ_Bŵ.rad2deg)")
        debugStrings.append(" v_Bŵ: \(v_Bŵ)")
        debugStrings.append(" V_Aŵ: \(V_Aŵ)")
        debugStrings.append(" V_AB̂: \(V_AB̂)")
        debugStrings.append(" θ_sB̂: \(θ_sB̂.rad2deg)")
        debugStrings.append("    B̂: \(B̂)")
        debugStrings.append("    l̂: \(l̂)")
        debugStrings.append("    α: \(α.rad2deg)")
        debugStrings.append(" CL_m: \(CL_mainsail)")
        debugStrings.append(" CD_m: \(CD_mainsail)")
        debugStrings.append("  L_m: \(L_mainsailŵ)")
        debugStrings.append("  D_m: \(D_mainsailŵ)")
        debugStrings.append(" tack: \(V_AB̂.θ > CGFloat.pi ? "port" : "starboard")")
        debugStrings.append("  D_h: \(D_hullŵ)")
        debugStrings.append("   FR: \(FR)")
        debugStrings.append(" FLAT: \(FLAT)")
        debugStrings.append("    F: \(F)")
        debugStrings.append(" Fh_s: \(Fh_sail)")
        debugStrings.append(" Fh_h: \(Fh_hull)")
        debugStrings.append(" τ_bb: \(τ_bb)")
        debugStrings.append("    b: \(b)")
        debugStrings.append("θ_bbŵ: \(θ_bbŵ.rad2deg)")
    }
    
    // UI updates
    func updateGraphics() {
        if rotateBoatNotView {
            self.windLabel?.zRotation = v_Tŵ.θ
            self.boatLabel?.zRotation = θ_Bŵ
        }
        else {
            self.windLabel?.zRotation = -θ_Bŵ+v_Tŵ.θ+CGFloat.pi/2
            self.boatLabel?.zRotation = CGFloat.pi/2
        }
        
        self.sternNode?.zRotation = -θ_bbŵ
        self.topSailNode?.zRotation = θ_sB̂+CGFloat.pi
        self.topForcesNode?.zRotation = V_AB̂.θ+CGFloat.pi
        
        let nf: NumberFormatter = {
            let temporaryFormatter = NumberFormatter()
            temporaryFormatter.maximumFractionDigits = 1
            temporaryFormatter.minimumFractionDigits = 1
            temporaryFormatter.maximumIntegerDigits = 3
            temporaryFormatter.minimumIntegerDigits = 3
            return temporaryFormatter
        }()
        
        
        
        self.sailLabel?.zRotation = θ_sB̂
        self.wobLabel?.zRotation = V_AB̂.θ
        self.speedLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(v_Bŵ⋅B̂)*1.943))!) kts"
        self.leewardLabel?.text = "\(nf.string(from: NSNumber.init(value: Double((v_Bŵ⋅v_Tŵ)/v_Tŵ.mag)*1.943))!) kts"
        self.frLabel?.text = "FR: \(nf.string(from: NSNumber.init(value: Double(FR⋅B̂)))!)"
        self.frlLabel?.text = "F.θ: \(nf.string(from: NSNumber.init(value: Double(F.θ.rad2deg)))!)"
        self.aaLabel?.text = "α: \(nf.string(from: NSNumber.init(value: Double(α.rad2deg)))!)"
        self.heelLabel?.text = "θ_bbŵ: \(nf.string(from: NSNumber.init(value: Double(θ_bbŵ.rad2deg)))!)"
        self.fhLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(Fh_sail.mag)))!)"
        self.lLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(L_mainsailŵ.mag)))!)"
        self.dLabel?.text = "\(nf.string(from: NSNumber.init(value: Double(D_mainsailŵ.mag)))!)"
        //self.water?.position.x -= Δx_Bŵ.dx*pixelsPerMeter
        //self.water?.position.y -= Δx_Bŵ.dy*pixelsPerMeter
        updateWater()
    }
    
    func updateWater() {
        self.enumerateChildNodes(withName: "water", using: ({
            (node, error) in
            node.position.x -= self.Δx_Bŵ.dx*self.pixelsPerMeter
            node.position.y -= self.Δx_Bŵ.dy*self.pixelsPerMeter
            
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
        if pos.x < -270 && pos.y > -mainSheetMax { sheetUpdated(toValue: pos.y) }
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
    static func ⊙ (left: CGVector, right: CGVector) -> CGVector {
        return right.normalized()*(left⋅right)
    }
    
}
