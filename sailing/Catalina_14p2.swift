//
//  Catalina_14p2.swift
//  sailing
//
//  Created by Taylor H. Gilbert on 7/5/17.
//  Copyright © 2017 Taylor H. Gilbert. All rights reserved.
//

import SpriteKit
import GameplayKit

class Catalina_14p2: Sloop {
    
    
    private let boatHeadingChangePerTillerKtSecond: CGFloat = 0.25 // radians/([]*m/s*s)
    
    init() {
        
        let boatBlueprint = BoatBlueprint(beam: 1.88, loa: 4.52, bowToCG: 2.26, tillerLength: 1.2, rudderExtension: 0.33, rudderDepth: 0.85, boatMass: 250, boatWaterContactArea: 7, hullCDForward: 0.005, hullCDLateral: 0.4, boatI: CGVector3(x: 500, y: 500, z: 500))
        
        let CD_mainsail = {
            (α: CGFloat) -> CGFloat in
            switch α {
            case 0 ..< CGFloat(50).deg2rad:
                return 0.2 + 1.4*pow(α/CGFloat(50).deg2rad,2)
            case CGFloat(50).deg2rad ..< CGFloat(100).deg2rad:
                return 1.6
            default:
                return 1.6 - 1.6*((α-CGFloat(80).deg2rad)/CGFloat(80).deg2rad)
            }
        }
        
        let CL_mainsail = {
            (α: CGFloat) -> CGFloat in
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
        }
        
        let catboatBlueprint = CatboatBlueprint(boatBlueprint: boatBlueprint, bowToMast: 1.52, boomLength: 2.59, mainsailArea: 6.81, mainsailHeight: 2.75, centerboardDepth: 1.07, mainsheetClosestHaul: 0.25, mainsailMaxAngle: 1.22, mainsailCD: CD_mainsail, mainsailCL: CL_mainsail)
        
        let sloopBlueprint = SloopBlueprint(catboatBlueprint: catboatBlueprint)
        
        super.init(blueprint: sloopBlueprint)
        
        self.zPosition = 0.5
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // Frame Updates
    /**
     - Parameters:
     - currentTime: time of simulation (will be subtracted from last submitted update within boat) [s]
     - wind: velocity of wind acting on boat [m/s]
     - tillerPosition: commanded position of tiller from -1 (full left turn) to 1 (full right turn) []
     - mainSheetPosition: commanded position of mainsheet from 0 (sheeted in) to 1 (sheeted out) []
     - Returns:
     change in boat position this update [m]
     */
    public func moveBoat(afterTime elapsedTime: TimeInterval, wind: CGVector3, tillerPosition tiller: CGFloat, mainSheetPosition mainsheet: CGFloat) {
        v_Tŵ = wind
        tillerPosition = tiller
        mainsheetPosition = mainsheet
        
        self.applyBoatEffect(effect: BoatEffect(force: CGVector3.zero, torque: CGVector3.zero), duration: elapsedTime)
        
        //Δx_Bŵ = CGPoint(x: v_Bŵ.dx*CGFloat(timeSinceLastScene), y: v_Bŵ.dy*CGFloat(timeSinceLastScene))
        //x_Bŵ = x_Bŵ + Δx_Bŵ
        //v_Bŵ = v_Bŵ + (FR+FLAT)/M_oboat*CGFloat(timeSinceLastScene)
        
        //Δθ_bbŵ = τ_bb / I_bb * CGFloat(timeSinceLastScene)
        //θ_bbŵ = θ_bbŵ + Δθ_bbŵ
        //if θ_bbŵ > CGFloat.pi/2 { θ_bbŵ = 0; ω_bbŵ = 0 }
        
        //let boatRotation = boatHeadingChangePerTillerKtSecond*tillerPosition*(v_Bŵ⋅B̂)*CGFloat(timeSinceLastScene)
        //v_Bŵ = v_Bŵ.rotatedBy(radians: boatRotation)
        //θ_Bŵ = θ_Bŵ + boatRotation
        
        self.mainsail?.zRotation = self.θ_sB̂ + CGFloat.pi // NEED TO MAKE ABSOLUTELY CORRECT
        self.mastTellTail?.zRotation = v_AB̂.θz + CGFloat.pi // NEED TO MAKE ABSOLUTELY CORRECT
        self.tiller?.zRotation = -self.tillerPosition*CGFloat.pi/3
    }
    
    
    // Printing
    public func statusString() -> String {
        
        var debugStrings = [String]()
        
        debugStrings.append(" v_Tŵ: \(v_Tŵ)")
        debugStrings.append(" x_Bŵ: (\(x_Bŵ.x), \(x_Bŵ.y))")
        debugStrings.append("x_Bŵ.θz: \(x_Bŵ.θz.rad2deg)")
        debugStrings.append(" v_Bŵ: \(v_Bŵ)")
//        debugStrings.append(" V_Aŵ: \(V_Aŵ)")
//        debugStrings.append(" V_AB̂: \(V_AB̂)")
        debugStrings.append(" θ_sB̂: \(θ_sB̂.rad2deg)")
//u        debugStrings.append("    B̂: \(B̂)")
//        debugStrings.append("    l̂: \(l̂)")
        debugStrings.append("    α: \(α.rad2deg)")
        debugStrings.append(" CL_m: \(CL_mainsail)")
        debugStrings.append(" CD_m: \(CD_mainsail)")
//        debugStrings.append("  L_m: \(L_mainsailŵ)")
//        debugStrings.append("  D_m: \(D_mainsailŵ)")
//        debugStrings.append(" tack: \(V_AB̂.θ > CGFloat.pi ? "port" : "starboard")")
//        debugStrings.append("  D_h: \(D_hullŵ)")
//        debugStrings.append("   FR: \(FR)")
//        debugStrings.append(" FLAT: \(FLAT)")
        debugStrings.append("    F: \(F_mainsail)")
//        debugStrings.append(" Fh_h: \(Fh_hull)")
//        debugStrings.append(" τ_bb: \(τ_bb)")
//        debugStrings.append("    b: \(b)")
        debugStrings.append("θ_bbŵ: \(x_Bŵ.θx.rad2deg)")
        
        var finalString = ""
        for debugString in debugStrings {
            finalString = finalString + debugString + "\n"
        }
        return finalString
        
    }
    
}

