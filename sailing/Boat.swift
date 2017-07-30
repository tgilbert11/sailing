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


infix operator ⋅ : MultiplicationPrecedence // dot product
infix operator ⊙ : MultiplicationPrecedence // projection

class Boat: SKSpriteNode {
    // global constants
    let g: CGFloat = 9.806 // m/s2
    let ρ_air: CGFloat = 1.225 // kg/m3
    let ρ_water: CGFloat = 1000 // kg/m3
    
    // constants
    let beam: CGFloat // m
    let loa: CGFloat // m
    let bowToCG: CGFloat // m
    let tillerLength: CGFloat // m
    let rudderExtension: CGFloat // m
    let rudderDepth: CGFloat // m
    let M_boat: CGFloat // kg
    let I_boat: CGVector3 // 1/Nms
    let S_boat: CGFloat // m2
    let CD_hull_R: CGFloat // [], 0.011 by lookup
    let CD_hull_LAT: CGFloat // []
    let I_bb: CGFloat // kg*m2, NEED TO REFINE
    
    // variables
    var x_Bŵ: CGVector3 = CGVector3.zero { didSet { self.position = CGPoint(x: self.x_Bŵ.x, y: self.x_Bŵ.y) } }
    var θ_Bŵ: CGVector3 = CGVector3.zero
    var v_Bŵ: CGVector3 = CGVector3.zero // m/s
    var ω_Bŵ: CGVector3 = CGVector3.zero
    //var θ_Bŵ: CGFloat = 0 // radians
    //var θ_bbŵ: CGFloat = 0 // radians
    //var ω_Bŵ: CGFloat = 0 // radians/s
    //var ω_bbŵ: CGFloat = 0 // radians/s
    var tillerPosition: CGFloat = 0 // [], [-1,1]
    
    // UI nodes
    var tiller: SKSpriteNode?
    
    // Simulation
    var lastSceneUpdateTime: TimeInterval? = 0
    
    // Computations
    var B̂: CGVector { get { return CGVector.init(normalWithAngle: θ_Bŵ.z) } } // []
    
    
    init(blueprint: BoatBlueprint) {
        
        self.beam = blueprint.beam
        self.loa = blueprint.loa
        self.bowToCG = blueprint.bowToCG
        self.tillerLength = blueprint.tillerLength
        self.rudderExtension = blueprint.rudderExtension
        self.rudderDepth = blueprint.rudderDepth
        self.M_boat = blueprint.boatMass
        self.S_boat = blueprint.boatWaterContactArea
        self.CD_hull_R = blueprint.hullCDForward
        self.CD_hull_LAT = blueprint.hullCDLateral
        self.I_bb = blueprint.boatIbb
        self.I_boat = blueprint.boatI
        
        super.init(texture: SKTexture(imageNamed: "boat flat transom"), color: .clear, size: CGSize(width: beam, height: loa))
        
        self.tiller = SKSpriteNode(imageNamed: "rudder")
        self.tiller?.size = CGSize(width: 0.1, height: self.tillerLength+self.rudderExtension)
        self.tiller?.anchorPoint = CGPoint(x: 0.5, y: self.rudderExtension/(self.rudderExtension+self.tillerLength))
        self.tiller?.position = CGPoint(x: 0, y: -0.5*self.loa)
        self.tiller?.zPosition = 1
        self.addChild(tiller!)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyBoatEffect(effect: BoatEffect, duration: TimeInterval) {
        // add effects of boat (centerboard, hull, rudder)
        let F_drag = 0.5 * ρ_water * (v_Bŵ⋅B̂) * abs(v_Bŵ⋅B̂) * S_boat * CD_hull_R
        
        // update the boat's velocity, angular torque, etc
        x_Bŵ += CGVector3(x: v_Bŵ.dx*CGFloat(duration), y: v_Bŵ.dy*CGFloat(duration), z: 0)
        v_Bŵ += CGVector(dx: CGFloat(effect.force.x)/M_boat*CGFloat(duration), dy: CGFloat(-effect.force.y)/M_boat*CGFloat(duration))
        
        θ_Bŵ += ω_Bŵ*CGFloat(duration)
        ω_Bŵ += CGFloat(effect.torque.z)/CGFloat(I_boat.z)*CGFloat(duration)
        
        θ_bbŵ += ω_bbŵ*CGFloat(duration)
        ω_bbŵ += CGFloat(effect.torque.x)/CGFloat(I_boat.x)*CGFloat(duration)
    }
        
}

struct BoatBlueprint {
    let beam: CGFloat // m
    let loa: CGFloat // m
    let bowToCG: CGFloat // m
    let tillerLength: CGFloat // m
    let rudderExtension: CGFloat // m
    let rudderDepth: CGFloat // m
    let boatMass: CGFloat // kg
    let boatWaterContactArea: CGFloat // m2
    let hullCDForward: CGFloat // []
    let hullCDLateral: CGFloat // []
    let boatIbb: CGFloat // kg*m2
    let boatI: CGVector3 // kg*m2?
}

struct BoatEffect {
    var force: CGVector3
    var torque: CGVector3
    static func + (left: BoatEffect, right: BoatEffect) -> BoatEffect {
        return BoatEffect(force: left.force+right.force, torque: left.torque+right.torque)
    }
    static func - (left: BoatEffect, right: BoatEffect) -> BoatEffect {
        return BoatEffect(force: left.force-right.force, torque: left.torque-right.torque)
    }
    static func += (left: inout BoatEffect, right: BoatEffect) {
        left.force += right.force
        left.torque += right.torque
    }
    static func -= (left: inout BoatEffect, right: BoatEffect) {
        left.force -= right.force
        left.torque -= right.torque
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
    static func += (left: inout CGVector, right: CGVector) {
        left.dx += right.dx
        left.dy += right.dy
    }
    static func -= (left: inout CGVector, right: CGVector) {
        left.dx -= right.dx
        left.dy -= right.dy
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

extension CGPoint {
    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x*right, y: left.y*right)
    }
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x+right.x, y: left.y+right.y)
    }
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x-right.x, y: left.y-right.y)
    }
    static func += (left: inout CGPoint, right: CGPoint) {
        left.x += right.x
        left.y += right.y
    }
    static func -= (left: inout CGPoint, right: CGPoint) {
        left.x -= right.x
        left.y -= right.y
    }
}

struct CGVector3 {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
    static let zero: CGVector3 = CGVector3(x: 0, y: 0, z: 0)
    
    static func + (left: CGVector3, right: CGVector3) -> CGVector3 {
        return CGVector3(x: left.x+right.x, y: left.y+right.y, z: left.z+right.z)
    }
    static func - (left: CGVector3, right: CGVector3) -> CGVector3 {
        return CGVector3(x: left.x-right.x, y: left.y-right.y, z: left.z-right.z)
    }
    static func += (left: inout CGVector3, right: CGVector3) {
        left.x += right.x
        left.y += right.y
        left.z += right.z
    }
    static func -= (left: inout CGVector3, right: CGVector3) {
        left.x -= right.x
        left.y -= right.y
        left.z -= right.z
    }

}
