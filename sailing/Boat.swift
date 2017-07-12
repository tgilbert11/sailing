//
//  Boat.swift
//  sailing
//
//  Created by Taylor H. Gilbert on 7/5/17.
//  Copyright © 2017 Taylor H. Gilbert. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit


infix operator ⋅ : MultiplicationPrecedence
infix operator ⊙ : MultiplicationPrecedence


class Boat: SKSpriteNode {
    let g: CGFloat = 9.806 // m/s2
    let ρ_air: CGFloat = 1.225 // kg/m3
    let ρ_water: CGFloat = 1000 // kg/m3
    
    var x_Bŵ = CGVector(dx: 0, dy: 0) // m
    var v_Bŵ = CGVector(dx: 0, dy: 0) // m/s
    var θ_Bŵ: CGFloat = 0 // radians
    var θ_bbŵ: CGFloat = 0 // radians
    
    let beam: CGFloat // m
    let loa: CGFloat // m
    let bowToMast: CGFloat // m
    let boomLength: CGFloat // m
    let tillerLength: CGFloat // m
    let mainsailAspectRatio: CGFloat = 13.5 // []
    let tillerAspectRatio: CGFloat = 12 // []
    
    let A_mainsail: CGFloat // m2
    let M_boat: CGFloat // kg
    let S_boat: CGFloat // m2
    let CD_hull_R: CGFloat // [], 0.011 by lookup
    let CD_hull_LAT: CGFloat // []
    let h_mainsail: CGFloat // m, height of force application on mainsail
    let c: CGFloat // m, depth of force application below CG
    let I_bb: CGFloat // kg*m2, NEED TO REFINE
    let mainSheetClosestHaul: CGFloat // radians
    let mainSailMaxAngle: CGFloat // radians
    
    
    var mainsail: SKSpriteNode?
    var mastTellTail: SKSpriteNode?
    var tiller: SKSpriteNode?
    
    var mainSheetPosition: CGFloat = 0
    var tillerPosition: CGFloat = 0
    var lastSceneUpdateTime: TimeInterval? = 0
    var v_Tŵ = CGVector.zero
    
    var θ_lB̂: CGFloat { get { return CGFloat.pi/2 + (V_AB̂.θ < CGFloat.pi ? CGFloat.pi : 0) } }
    var θ_lŵ: CGFloat { get { return θ_lB̂ + θ_Bŵ } } // radians
    var B̂: CGVector { get { return CGVector.init(normalWithAngle: θ_Bŵ) } } // [], SHOULD BE PRIVATE
    var l̂: CGVector { get { return CGVector.init(normalWithAngle: θ_lŵ) } } // []
    var V_Aŵ: CGVector { get { return v_Tŵ - v_Bŵ } } // m/s
    var V_AB̂: CGVector { get { return V_Aŵ.rotatedBy(radians: -θ_Bŵ) } } // m/s, MAYBE PRIVATE
    
    var α: CGFloat { get { return abs(V_AB̂.θ-θ_sB̂) } } // radians, MAYBE PRIVATE
    var L_mainsailŵ: CGVector { get { return V_Aŵ.rotatedBy(radians: θ_lB̂).normalized() * 0.5 * ρ_air * V_Aŵ.mag2 * A_mainsail * cos(θ_bbŵ) * CL_mainsail(α) } } // N, SHOULD BE PRIVATE
    var D_mainsailŵ: CGVector { get { return V_Aŵ/V_Aŵ.mag * 0.5 * ρ_air * V_Aŵ.mag2 * A_mainsail * cos(θ_bbŵ) * CD_mainsail(α) } } // N, SHOULD BE PRIVATE
    var D_hullŵ: CGVector { get { return
        B̂ * -0.5 * ρ_water * (v_Bŵ⋅B̂) * abs(v_Bŵ⋅B̂) * S_boat * CD_hull_R
            - l̂ * 0.5 * ρ_water * (v_Bŵ⋅l̂) * abs(v_Bŵ⋅l̂) * S_boat * cos(θ_bbŵ) * CD_hull_LAT } } // N
    
    var FR: CGVector { get { return L_mainsailŵ⊙B̂ + D_mainsailŵ⊙B̂ + D_hullŵ⊙B̂ } } // N, SHOULD BE PRIVATE
    var Fh_sail: CGVector { get { return L_mainsailŵ⊙l̂ + D_mainsailŵ⊙l̂ } } // N, SHOULD BE PRIVATE
    var Fh_hull: CGVector { get { return D_hullŵ⊙l̂ } } // N
    var FLAT: CGVector { get { return Fh_sail + Fh_hull } } // N
    var F: CGVector { get { return FR + FLAT } } // N, SHOULD BE PRIVATE
    
    var τ_bb: CGFloat { get { return Fh_hull.mag*c + Fh_sail.mag*h_mainsail - M_boat*g*b } } // Nm
    var b: CGFloat { get { return 0.4*sin(2.4*θ_bbŵ) } } // m
    
    var θ_sB̂: CGFloat { get {
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
    
    let CD_mainsail: ((CGFloat) -> CGFloat)
    let CL_mainsail: ((CGFloat) -> CGFloat)
    
    init(beam: CGFloat, loa: CGFloat, bowToMast: CGFloat, boomLength: CGFloat, tillerLength: CGFloat,
         mainsailArea: CGFloat, boatMass: CGFloat, boatWaterContactArea: CGFloat, hullCDForward: CGFloat,
         hullCDLateral: CGFloat, mainsailAverageHeight: CGFloat, centerboardAverageDepth: CGFloat, boatIbb: CGFloat,
         mainSheetClosestHaul: CGFloat, mainSailMaxAngle: CGFloat, cdMainsail: @escaping ((CGFloat) -> CGFloat),
        clMainsail: @escaping ((CGFloat) -> CGFloat)) {
        
        self.beam = beam
        self.loa = loa
        self.bowToMast = bowToMast
        self.boomLength = boomLength
        self.tillerLength = tillerLength
        self.A_mainsail = mainsailArea
        self.M_boat = boatMass
        self.S_boat = boatWaterContactArea
        self.CD_hull_R = hullCDForward
        self.CD_hull_LAT = hullCDLateral
        self.h_mainsail = mainsailAverageHeight
        self.c = centerboardAverageDepth
        self.I_bb = boatIbb
        self.mainSheetClosestHaul = mainSheetClosestHaul
        self.mainSailMaxAngle = mainSailMaxAngle
        self.CD_mainsail = cdMainsail
        self.CL_mainsail = clMainsail
        
        super.init(texture: SKTexture(imageNamed: "boat flat transom"), color: .clear, size: CGSize(width: beam, height: loa))
        
        self.mainsail = SKSpriteNode(imageNamed: "sail top boom")
        self.mastTellTail = SKSpriteNode(imageNamed: "mast tell tail")
        self.tiller = SKSpriteNode(imageNamed: "rudder")
        
        self.mainsail?.size = CGSize(width: boomLength/mainsailAspectRatio, height: boomLength)
        self.mainsail?.anchorPoint = CGPoint(x: 0.5, y: 1-1/mainsailAspectRatio/2)
        self.mainsail?.position = CGPoint(x: 0, y: (0.5*self.loa - self.bowToMast))
        self.mainsail?.zPosition = 3
        self.addChild(self.mainsail!)
        
        self.mastTellTail?.size = CGSize(width: 0.08, height: 1.5)
        self.mastTellTail?.anchorPoint = CGPoint(x: 0.5, y: 0.95)
        self.mastTellTail?.position = self.mainsail!.position
        self.mastTellTail?.zPosition = 4
        self.addChild(self.mastTellTail!)
        
        self.tiller?.size = CGSize(width: self.tillerLength/self.tillerAspectRatio, height: self.tillerLength)
        self.tiller?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.tiller?.position = CGPoint(x: 0, y: -0.5*self.loa)
        self.tiller?.zPosition = 1
        self.addChild(tiller!)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
       
}



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
