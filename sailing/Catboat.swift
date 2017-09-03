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
    var v_Tŵ = CGVector3.zero
    var v_Aŵ: CGVector3 { return v_Tŵ - v_Bŵ } // m/s
    var v_AB̂: CGVector3 { return v_Aŵ.rotatedBy(transform: CGVector3(x: 0, y: 0, z: -θ_BŵB̂.z)) } // m/s
//    var v_AB̂: CGVector3 { return v_Aŵ.rotatedInZBy(θ: -θ_BŵB̂.z) } // m/s
    var sailout: CGFloat { return mainsheetClosestHaul + (mainsailMaxAngle-mainsheetClosestHaul)*mainsheetPosition } // radians
    var α: CGFloat { return abs(v_AB̂.θz - CGFloat.pi) > sailout ? ( CGFloat.pi - v_AB̂.θz + (v_AB̂.θz > CGFloat.pi ? 1 : -1) * sailout) : 0 } // radians
    var θ_sB̂: CGFloat { return v_AB̂.θz + α }
    var Lŵ_θz: CGFloat { return v_Aŵ.θz + (α < 0 ? 1 : -1)*CGFloat.pi/2 } // radians
    var L_mag: CGFloat { return 0.5 * ρ_air * A_mainsail * cos(θ_BŵB̂.x) * CL_mainsail(abs(α)) * v_Aŵ.mag2 }
    var D_mag: CGFloat { return 0.5 * ρ_air * A_mainsail * CD_mainsail(abs(α)) * v_Aŵ.mag2 }
    var F_msŵ: CGVector3 { return CGVector3(x: L_mag*cos(Lŵ_θz) + D_mag*cos(v_Aŵ.θz), y: L_mag*sin(Lŵ_θz) + D_mag*sin(v_Aŵ.θz), z: 0) }
    
    // rudder
    var l_r: CGFloat { return loa-bowToCG+(rudderExtension+0.1)/2 }
    var v_raŵ: CGVector3 { return -v_Bŵ + CGVector3(x: -(ω_BŵB̂.z * l_r * sin(θ_BŵB̂.z)), y: ω_BŵB̂.z * l_r * cos(θ_BŵB̂.z), z: 0) }
    var θ_rB̂: CGFloat { return -tillerPosition * tillerRate }
    var θ_rŵ: CGFloat { return θ_BŵB̂.z + θ_rB̂ }
    var α_r: CGFloat { return (θ_rŵ - v_raŵ.θz + CGFloat.pi).normalizedAngle() }
    var C_Lr: CGFloat { return 1.6*sin(2*α_r) }
    var C_Dr: CGFloat { return 1.2*abs(sin(α_r)) }
    var L_rmag: CGFloat { return 0.5 * ρ_water * rudderDepth * (rudderExtension-0.1) * C_Lr * v_raŵ.mag2 }
    var D_rmag: CGFloat { return 0.5 * ρ_water * rudderDepth * (rudderExtension-0.1) * C_Dr * v_raŵ.mag2 }
    var θ_Lrŵ: CGFloat { return v_raŵ.θz - CGFloat.pi/2 }
    var θ_Drŵ: CGFloat { return v_raŵ.θz }
    var F_rŵ: CGVector3 { return CGVector3(x: L_rmag*cos(θ_Lrŵ) + D_rmag*cos(θ_Drŵ), y: L_rmag*sin(θ_Lrŵ) + D_rmag*sin(θ_Drŵ), z: 0) }

 
    // MISSING!!!
    var τ_bb: CGFloat { return 0 } // Nm
    var b: CGFloat { return 0 } // m
    
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
        
        self.mainsail = SKSpriteNode(imageNamed: "boom")
        self.mainsail?.size = CGSize(width: boomLength, height: boomLength/mainsailAspectRatio)
        self.mainsail?.anchorPoint = CGPoint(x: 1-1/mainsailAspectRatio/2, y: 0.5)
        self.mainsail?.position = CGPoint(x: (0.5*self.loa - self.bowToMast), y: 0)
        self.mainsail?.zPosition = 3
        self.addChild(self.mainsail!)
        
        self.mastTellTail = SKSpriteNode(imageNamed: "mastTellTail")
        self.mastTellTail?.size = CGSize(width: 1, height: 0.1)
        self.mastTellTail?.anchorPoint = CGPoint(x: 0.95, y: 0.5)
        self.mastTellTail?.position = self.mainsail!.position
        self.mastTellTail?.zPosition = 4
        self.addChild(self.mastTellTail!)
        
    }
    
    override func advanceSimulationBy(duration: TimeInterval) {
        
        applyForce(force_ŵ: F_msŵ, atPoint_b̂: CGVector3(x: self.bowToCG - self.bowToMast - self.boomLength/3*cos(θ_sB̂), y: self.boomLength/3*sin(θ_sB̂), z: 0))
        
        // need to figure out rudder, shoudn't be hard
        //applyForce(force_ŵ: F_rŵ, atPoint_b̂: CGVector3(x: <#T##CGFloat#>, y: <#T##CGFloat#>, z: <#T##CGFloat#>))
        
        super.advanceSimulationBy(duration: duration)
    }
    
    override func applyBoatEffect(effect: BoatEffect, duration: TimeInterval) {
        print("L_mag: \(L_mag)")
        print("L_ang: \(Lŵ_θz)")
        print("D_mag: \(D_mag)")
        print("D_ang: \(v_Aŵ.θz)")
        print("abs(v_AB.tz - pi): \(abs(v_AB̂.θz - CGFloat.pi))")
        
        let torque_x = self.bowToCG-self.bowToMast-self.boomLength/3*cos(θ_sB̂)
        let torque_y = self.boomLength/3*sin(θ_sB̂)
        let torque = CGVector3.torqueFromForce(force: F_msŵ, appliedAt: CGVector3(x: torque_x*cos(θ_BŵB̂.z), y: torque_y*sin(θ_BŵB̂.z), z: 0))
        print("    torque)")
        
        
        super.applyBoatEffect(effect: effect + BoatEffect(force: F_msŵ, torque: torque), duration: duration)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

struct CatboatBlueprint {
    let boatBlueprint: BoatBlueprint
    let bowToMast: CGFloat // m
    let boomLength: CGFloat // m
    let mainsailAspectRatio: CGFloat = 20 // []
    let mainsailArea: CGFloat // m2
    let mainsailHeight: CGFloat // m, height of force application on mainsail
    let centerboardDepth: CGFloat // m, depth of force application below CG
    let mainsheetClosestHaul: CGFloat // radians
    let mainsailMaxAngle: CGFloat // radians
    let mainsailCD: ((CGFloat) -> CGFloat)
    let mainsailCL: ((CGFloat) -> CGFloat)
}
