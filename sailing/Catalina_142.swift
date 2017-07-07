//
//  Catalina_142.swift
//  sailing
//
//  Created by Taylor H. Gilbert on 7/5/17.
//  Copyright © 2017 Taylor H. Gilbert. All rights reserved.
//

import SpriteKit
import GameplayKit

infix operator ⋅ : MultiplicationPrecedence
infix operator ⊙ : MultiplicationPrecedence

class Catalina_142: Boat {
    
    // world = ŵ
    // boat = B̂
    //    lat = l̂
    // V_Aŵ = â
    // sail = ŝ
    
    // sail forces act in â
    // hull forces act in b̂ (boat right/lat is l̂)
    // position and velocity are in ŵ
    
    // input variables
    private var mainSheetPosition: CGFloat
    private var tillerPosition: CGFloat
    private var lastSceneUpdateTime: TimeInterval?
    private var v_Tŵ = CGVector.zero
    private let pixelsPerMeter: CGFloat
    private let mainsailAspectRatio: CGFloat = 13.5
    
    private let beam: CGFloat = 1.88 // m
    private let loa: CGFloat = 4.32 // m
    private let bowToMast: CGFloat = 1.52 // m
    private let boomLength: CGFloat = 2.59 // m
    
    // Game Control
    
    
    // Child SKNodes
    private var mainsail: SKSpriteNode?
    private var mastTellTail: SKSpriteNode?
    
    // Constants
    
    public let tillerMax: CGFloat = 300 // pixels, SHOULD BE PRIVATE
    
    private let mainSheetClosestHaul: CGFloat = 0.25 // radians
    public let mainSheetMax: CGFloat = 400 // pixels, SHOULD BE PRIVATE
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
    public var B̂: CGVector { get { return CGVector.init(normalWithAngle: θ_Bŵ) } } // [], SHOULD BE PRIVATE
    private var l̂: CGVector { get { return CGVector.init(normalWithAngle: θ_lŵ) } } // []
    private var V_Aŵ: CGVector { get { return v_Tŵ - v_Bŵ } } // m/s
    public var V_AB̂: CGVector { get { return V_Aŵ.rotatedBy(radians: -θ_Bŵ) } } // m/s  // SHOULD BE PRIVATE
    
    public var α: CGFloat { get { return abs(V_AB̂.θ-θ_sB̂) } } // radians, SHOULD BE PRIVATE
    public var L_mainsailŵ: CGVector { get { return V_Aŵ.rotatedBy(radians: θ_lB̂).normalized() * 0.5 * ρ_air * V_Aŵ.mag2 * A_mainsail * cos(θ_bbŵ) * CL_mainsail } } // N, SHOULD BE PRIVATE
    public var D_mainsailŵ: CGVector { get { return V_Aŵ/V_Aŵ.mag * 0.5 * ρ_air * V_Aŵ.mag2 * A_mainsail * cos(θ_bbŵ) * CD_mainsail } } // N, SHOULD BE PRIVATE
    private var D_hullŵ: CGVector { get { return
        B̂ * -0.5 * ρ_water * (v_Bŵ⋅B̂) * abs(v_Bŵ⋅B̂) * S_boat * CD_hull_R
            - l̂ * 0.5 * ρ_water * (v_Bŵ⋅l̂) * abs(v_Bŵ⋅l̂) * S_boat * cos(θ_bbŵ) * CD_hull_LAT } } // N
    
    public var FR: CGVector { get { return L_mainsailŵ⊙B̂ + D_mainsailŵ⊙B̂ + D_hullŵ⊙B̂ } } // N, SHOULD BE PRIVATE
    public var Fh_sail: CGVector { get { return L_mainsailŵ⊙l̂ + D_mainsailŵ⊙l̂ } } // N, SHOULD BE PRIVATE
    private var Fh_hull: CGVector { get { return D_hullŵ⊙l̂ } } // N
    private var FLAT: CGVector { get { return Fh_sail + Fh_hull } } // N
    public var F: CGVector { get { return FR + FLAT } } // N, SHOULD BE PRIVATE
    
    private var τ_bb: CGFloat { get { return Fh_hull.mag*c + Fh_sail.mag*h_mainsail - M_boat*g*b } } // Nm
    private var b: CGFloat { get { return 0.4*sin(2.4*θ_bbŵ) } } // m
    
    
    // try to make this absolute value, rather than conditional
    public var θ_sB̂: CGFloat { get {
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
    
    init(pixelsPerMeter: CGFloat) {
        
        
        self.mainSheetPosition = 0
        self.tillerPosition = 0
        self.pixelsPerMeter = pixelsPerMeter
        
        self.mainsail = SKSpriteNode(imageNamed: "sail top boom")
        self.mastTellTail = SKSpriteNode(imageNamed: "mast tell tail")
        
        super.init(texture: SKTexture(imageNamed: "boat flat transom"), color: .black, size: CGSize(width: beam*self.pixelsPerMeter, height: loa*pixelsPerMeter))
        
        self.mainsail?.size = CGSize(width: boomLength*self.pixelsPerMeter/mainsailAspectRatio, height: boomLength*self.pixelsPerMeter)
        self.mainsail?.anchorPoint = CGPoint(x: 0.5, y: 1-1/mainsailAspectRatio/2)
        self.mainsail?.position = CGPoint(x: 0, y: self.pixelsPerMeter*(0.5*self.loa - self.bowToMast))
        self.mainsail?.zPosition = 1
        self.addChild(self.mainsail!)
        
        self.mastTellTail?.size = CGSize(width: 0.15*pixelsPerMeter, height: 1.5*pixelsPerMeter)
        self.mastTellTail?.anchorPoint = CGPoint(x: 0.5, y: 0.95)
        self.mastTellTail?.position = self.mainsail!.position
        self.mastTellTail?.zPosition = 2
        self.addChild(self.mastTellTail!)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Frame Updates
    public func calculateFrame(atTime currentTime: TimeInterval, wind: CGVector, tillerPosition tiller: CGFloat, mainSheetPosition mainsheet: CGFloat) {
        // Called before each frame is rendered
        v_Tŵ = wind
        tillerPosition = tiller
        mainSheetPosition = mainsheet
        let timeSinceLastScene = currentTime - (lastSceneUpdateTime ?? currentTime)
        lastSceneUpdateTime = currentTime
        
        //printCalculations()
        
        Δx_Bŵ = v_Bŵ * CGFloat(timeSinceLastScene)
        x_Bŵ = x_Bŵ + Δx_Bŵ
        v_Bŵ = v_Bŵ + (FR+FLAT)/M_boat*CGFloat(timeSinceLastScene)
        
        Δθ_bbŵ = τ_bb / I_bb * CGFloat(timeSinceLastScene)
        θ_bbŵ = θ_bbŵ + Δθ_bbŵ
        if θ_bbŵ > CGFloat.pi/2 { θ_bbŵ = 0 }
        
        let boatRotation = boatHeadingChangePerTillerKtSecond*tillerPosition*(v_Bŵ⋅B̂)*CGFloat(timeSinceLastScene)
        v_Bŵ = v_Bŵ.rotatedBy(radians: boatRotation)
        θ_Bŵ = θ_Bŵ + boatRotation
        
        self.mainsail?.zRotation = self.θ_sB̂ + CGFloat.pi // NEED TO MAKE ABSOLUTELY CORRECT
        self.mastTellTail?.zRotation = self.V_AB̂.θ + CGFloat.pi // NEED TO MAKE ABSOLUTELY CORRECT
        
    }
    
    // Printing
    public func statusString() -> String {
        
        var debugStrings = [String]()
        
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
        
        var finalString = ""
        for debugString in debugStrings {
            finalString = finalString + debugString + "\n"
        }
        return finalString
        
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
