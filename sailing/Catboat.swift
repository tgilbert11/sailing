//
//  Catboat.swift
//  sailing
//
//  Created by Taylor H. Gilbert on 7/12/17.
//  Copyright © 2017 Taylor H. Gilbert. All rights reserved.
//

import Foundation
import SpriteKit

class Catboat: Boat {
    
    // constants
    let bowToMast: CGFloat // m
    let boomLength: CGFloat // m
    let mainsailAspectRatio: CGFloat // []
    let A_mainsail: CGFloat // m2
    let h_mainsail: CGFloat // m, height of force application on mainsail
    let c: CGFloat // m, depth of force application below CG
    let mainsheetClosestHaul: CGFloat // radians
    let mainsailMaxAngle: CGFloat // radians
    let CD_mainsail: ((CGFloat) -> CGFloat)
    let CL_mainsail: ((CGFloat) -> CGFloat)
    
    // variables
    var mainsheetPosition: CGFloat = 0
    
    // UI elements
    var mainsail: SKSpriteNode?
    var mastTellTail: SKSpriteNode?
    
    // computations
    var v_Tŵ = CGVector.zero
    var θ_lB̂: CGFloat { get { return CGFloat.pi/2 + (V_AB̂.θ < CGFloat.pi ? CGFloat.pi : 0) } }
    var θ_lŵ: CGFloat { get { return θ_lB̂ + θ_Bŵ } } // radians
    var l̂: CGVector { get { return CGVector.init(normalWithAngle: θ_lŵ) } } // []
    var V_Aŵ: CGVector { get { return v_Tŵ - v_Bŵ } } // m/s
    var V_AB̂: CGVector { get { return V_Aŵ.rotatedBy(radians: -θ_Bŵ) } } // m/s
    
    var α: CGFloat { get { return abs(V_AB̂.θ-θ_sB̂) } } // radians
    var L_mainsailŵ: CGVector { get { return V_Aŵ.rotatedBy(radians: θ_lB̂).normalized() * 0.5 * ρ_air * V_Aŵ.mag2 * A_mainsail * cos(θ_bbŵ) * CL_mainsail(α) } } // N
    var D_mainsailŵ: CGVector { get { return V_Aŵ/V_Aŵ.mag * 0.5 * ρ_air * V_Aŵ.mag2 * A_mainsail * cos(θ_bbŵ) * CD_mainsail(α) } } // N
    var D_hullŵ: CGVector { get { return
        B̂ * -0.5 * ρ_water * (v_Bŵ⋅B̂) * abs(v_Bŵ⋅B̂) * S_boat * CD_hull_R
            - l̂ * 0.5 * ρ_water * (v_Bŵ⋅l̂) * abs(v_Bŵ⋅l̂) * S_boat * cos(θ_bbŵ) * CD_hull_LAT } } // N
    
    var FR: CGVector { get { return L_mainsailŵ⊙B̂ + D_mainsailŵ⊙B̂ + D_hullŵ⊙B̂ } } // N
    var Fh_sail: CGVector { get { return L_mainsailŵ⊙l̂ + D_mainsailŵ⊙l̂ } } // N
    var Fh_hull: CGVector { get { return D_hullŵ⊙l̂ } } // N
    var FLAT: CGVector { get { return Fh_sail + Fh_hull } } // N
    var F: CGVector { get { return FR + FLAT } } // N
    
    var τ_bb: CGFloat { get { return Fh_hull.mag*c/2 + Fh_sail.mag*h_mainsail - M_boat*g*b } } // Nm
    var b: CGFloat { get { return 0.4*sin(2.4*θ_bbŵ) } } // m
    
    var θ_sB̂: CGFloat { get {
        if V_AB̂.θ < CGFloat.pi - mainsheetClosestHaul - (mainsailMaxAngle - mainsheetClosestHaul)*mainsheetPosition {
            return CGFloat.pi - (mainsheetClosestHaul + (mainsailMaxAngle - mainsheetClosestHaul)*mainsheetPosition)
        }
        else if V_AB̂.θ > CGFloat.pi + mainsheetClosestHaul + (mainsailMaxAngle-mainsheetClosestHaul)*mainsheetPosition {
            return CGFloat.pi + mainsheetClosestHaul + (mainsailMaxAngle-mainsheetClosestHaul)*mainsheetPosition
        }
        else {
            return V_AB̂.θ
        }
        }}
    
    
    init(blueprint: CatboatBlueprint) {
        
        self.bowToMast = blueprint.bowToMast
        self.boomLength = blueprint.boomLength
        self.mainsailAspectRatio = blueprint.mainsailAspectRatio
        self.A_mainsail = blueprint.mainsailArea
        self.h_mainsail = blueprint.mainsailHeight
        self.c = blueprint.centerboardDepth
        self.mainsheetClosestHaul = blueprint.mainsheetClosestHaul
        self.mainsailMaxAngle = blueprint.mainsailMaxAngle
        self.CD_mainsail = blueprint.mainsailCD
        self.CL_mainsail = blueprint.mainsailCL
        
        super.init(blueprint: blueprint.boatBlueprint)
        
        self.mainsail = SKSpriteNode(imageNamed: "sail top boom")
        self.mainsail?.size = CGSize(width: boomLength/mainsailAspectRatio, height: boomLength)
        self.mainsail?.anchorPoint = CGPoint(x: 0.5, y: 1-1/mainsailAspectRatio/2)
        self.mainsail?.position = CGPoint(x: 0, y: (0.5*self.loa - self.bowToMast))
        self.mainsail?.zPosition = 3
        self.addChild(self.mainsail!)
        
        self.mastTellTail = SKSpriteNode(imageNamed: "mast tell tail")
        self.mastTellTail?.size = CGSize(width: 0.08, height: 1.5)
        self.mastTellTail?.anchorPoint = CGPoint(x: 0.5, y: 0.95)
        self.mastTellTail?.position = self.mainsail!.position
        self.mastTellTail?.zPosition = 4
        self.addChild(self.mastTellTail!)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

struct CatboatBlueprint {
    let boatBlueprint: BoatBlueprint
    let bowToMast: CGFloat // m
    let boomLength: CGFloat // m
    let mainsailAspectRatio: CGFloat = 13.5 // []
    let mainsailArea: CGFloat // m2
    let mainsailHeight: CGFloat // m, height of force application on mainsail
    let centerboardDepth: CGFloat // m, depth of force application below CG
    let mainsheetClosestHaul: CGFloat // radians
    let mainsailMaxAngle: CGFloat // radians
    let mainsailCD: ((CGFloat) -> CGFloat)
    let mainsailCL: ((CGFloat) -> CGFloat)
}
