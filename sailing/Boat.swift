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
    // global constants
    let g: CGFloat = 9.806 // m/s2
    let ρ_air: CGFloat = 1.225 // kg/m3
    let ρ_water: CGFloat = 1000 // kg/m3
    
    // constants
    let beam: CGFloat // m
    let loa: CGFloat // m
    let tillerLength: CGFloat // m
    let tillerAspectRatio: CGFloat // []
//    let tillerAspectRatio: CGFloat = 12 // []
    let M_boat: CGFloat // kg
    let S_boat: CGFloat // m2
    let CD_hull_R: CGFloat // [], 0.011 by lookup
    let CD_hull_LAT: CGFloat // []
    let I_bb: CGFloat // kg*m2, NEED TO REFINE
    
    // variables
    var x_Bŵ = CGVector(dx: 0, dy: 0) // m
    var v_Bŵ = CGVector(dx: 0, dy: 0) // m/s
    var θ_Bŵ: CGFloat = 0 // radians
    var θ_bbŵ: CGFloat = 0 // radians
    var tillerPosition: CGFloat = 0 // [], [-1,1]
    
    // UI nodes
    var tiller: SKSpriteNode?
    
    // Simulation
    var lastSceneUpdateTime: TimeInterval? = 0
    
    
    
    init(blueprint: BoatBlueprint) {
//        init(beam: CGFloat, loa: CGFloat, bowToMast: CGFloat, boomLength: CGFloat, tillerLength: CGFloat,
//        mainsailArea: CGFloat, boatMass: CGFloat, boatWaterContactArea: CGFloat, hullCDForward: CGFloat,
//        hullCDLateral: CGFloat, mainsailAverageHeight: CGFloat, centerboardAverageDepth: CGFloat, boatIbb: CGFloat,
//        mainSheetClosestHaul: CGFloat, mainSailMaxAngle: CGFloat, cdMainsail: @escaping ((CGFloat) -> CGFloat),
//        clMainsail: @escaping ((CGFloat) -> CGFloat)) {
        
        self.beam = blueprint.beam
        self.loa = blueprint.loa
        self.tillerLength = blueprint.tillerLength
        self.tillerAspectRatio = blueprint.tillerAspectRatio
        self.M_boat = blueprint.boatMass
        self.S_boat = blueprint.boatWaterContactArea
        self.CD_hull_R = blueprint.hullCDForward
        self.CD_hull_LAT = blueprint.hullCDLateral
        self.I_bb = blueprint.boatIbb
        
        super.init(texture: SKTexture(imageNamed: "boat flat transom"), color: .clear, size: CGSize(width: beam, height: loa))
        
        self.tiller = SKSpriteNode(imageNamed: "rudder")
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

struct BoatBlueprint {
    let beam: CGFloat // m
    let loa: CGFloat // m
    let tillerLength: CGFloat // m
    let tillerAspectRatio: CGFloat // []
    let boatMass: CGFloat // kg
    let boatWaterContactArea: CGFloat // m2
    let hullCDForward: CGFloat // []
    let hullCDLateral: CGFloat // []
    let boatIbb: CGFloat // kg*m2
}
