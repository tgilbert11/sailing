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
    let S_boat: CGFloat // m2
    let CD_hull_R: CGFloat // [], 0.011 by lookup
    let CD_hull_LAT: CGFloat // []
    let I_boat: CGVector3 // 1/Nms
    let tillerRate: CGFloat = 1 // radians/[]
    
    // variables
    var x_Bŵ: CGVector3 = CGVector3.zero { didSet { self.position = CGPoint(x: self.x_Bŵ.x*GameViewController.pixelsPerMeter, y: self.x_Bŵ.y*GameViewController.pixelsPerMeter) } }
    var v_Bŵ: CGVector3 = CGVector3.zero // m/s
    var θ_BŵB̂: CGVector3 = CGVector3.zero
    var ω_BŵB̂: CGVector3 = CGVector3.zero
    var tillerPosition: CGFloat = 0 // [], [-1,1]
    
    // UI nodes
    var tiller: SKSpriteNode?
    
    // Simulation
    var lastSceneUpdateTime: TimeInterval? = 0
    var forces: [CGVector3] = []
    var torques: [CGVector3] = []
    
    // Computations
    
    
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
        self.I_boat = blueprint.boatI
        
        super.init(texture: SKTexture(imageNamed: "catalinaHullTop2"), color: .clear, size: CGSize(width: loa, height: beam))
        
        self.tiller = SKSpriteNode(imageNamed: "rudderRight2")
        self.tiller?.size = CGSize(width: self.tillerLength+self.rudderExtension, height: 0.1)
        self.tiller?.anchorPoint = CGPoint(x: self.rudderExtension, y: 0.5)
        self.tiller?.position = CGPoint(x: -0.5*self.loa, y: 0)
        self.tiller?.zPosition = 1
        self.addChild(tiller!)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func advanceSimulationBy(duration: TimeInterval) {
        let D_LAT_mag = 0.5 * ρ_water * S_boat * CD_hull_LAT * pow(v_Bŵ.mag*sin(v_Bŵ.θz-θ_BŵB̂.z),2)
        let θ_D_LATŵ = θ_BŵB̂.z + (sin(v_Bŵ.θz-θ_BŵB̂.z)>0 ? -1 : 1)*CGFloat.pi/2
        applyForce(force_ŵ: CGVector3(x: D_LAT_mag*cos(θ_D_LATŵ), y: D_LAT_mag*sin(θ_D_LATŵ), z: 0) , atPoint_b̂: CGVector3.zero)

        let D_R_mag = 0.5 * ρ_water * S_boat * CD_hull_R * pow(v_Bŵ.mag*cos(v_Bŵ.θz-θ_BŵB̂.z),2)
        let θ_D_Rŵ = θ_BŵB̂.z + (cos(v_Bŵ.θz-θ_BŵB̂.z) > 0 ? 1 : 0) * CGFloat.pi
        applyForce(force_ŵ: CGVector3(x: D_R_mag*cos(θ_D_Rŵ), y: D_R_mag*sin(θ_D_Rŵ), z: 0) , atPoint_b̂: CGVector3.zero)
        
        
        let F = forces.reduce(CGVector3.zero) {$0 + $1}
        let τ = torques.reduce(CGVector3.zero) {$0 + $1}
        
        x_Bŵ += v_Bŵ*CGFloat(duration)
        v_Bŵ += F/M_boat*CGFloat(duration)
        
        θ_BŵB̂ += ω_BŵB̂*CGFloat(duration)
        ω_BŵB̂ += τ/I_boat*CGFloat(duration)
        
        forces.removeAll()
        torques.removeAll()
        
        self.tiller?.zRotation = θ_rB̂
    }
    
    func applyForce(force_ŵ force: CGVector3, atPoint_b̂ point: CGVector3) {
        self.forces.append(force)
        self.torques.append(force.rotatedBy(transform: -θ_BŵB̂).torqueFromApplyingAtLocation(r: point))
    }
    
    func applyBoatEffect(effect: BoatEffect, duration: TimeInterval) {
        
        // add effects of boat (centerboard, hull, rudder)
        let D_LAT_mag = 0.5 * ρ_water * S_boat * CD_hull_LAT * pow(v_Bŵ.mag*sin(v_Bŵ.θz-θ_BŵB̂.z),2)
        let θ_D_LATŵ = θ_BŵB̂.z + (sin(v_Bŵ.θz-θ_BŵB̂.z)>0 ? -1 : 1)*CGFloat.pi/2
        
        let D_R_mag = 0.5 * ρ_water * S_boat * CD_hull_R * pow(v_Bŵ.mag*cos(v_Bŵ.θz-θ_BŵB̂.z),2)
        let θ_D_Rŵ = θ_BŵB̂.z + (cos(v_Bŵ.θz-θ_BŵB̂.z) > 0 ? 1 : 0) * CGFloat.pi
        
        let fullEffect = effect + BoatEffect(force: CGVector3(x: D_LAT_mag*cos(θ_D_LATŵ) + D_R_mag*cos(θ_D_Rŵ), y: D_LAT_mag*sin(θ_D_LATŵ) + D_R_mag*sin(θ_D_Rŵ), z: 0), torque: CGVector3(x: 0, y: 0, z: -F_rudder.mag*sin(F_rudder.θz-θ_BŵB̂.z)))
        
        
        
        // update the boat's velocity, angular torque, etc
        print("  F_r: \(F_rudder)")
        print("v_raŵ: \(v_raŵ)")
        print("v_raŵ.θz: \(v_raŵ.θz)")
        print(" θ_rŵ: \(θ_rŵ)")
        print("  α_r: \(α_r)")
        print(" C_Lr: \(C_Lr)")
        print("L_mag: \(L_rmag)")
        print("θ_Lrŵ: \(θ_Lrŵ)")
        print("    τ: \(fullEffect.torque)")
        print(" θ_Bŵ: \(θ_BŵB̂)")
        print(" ω_Bŵ: \(ω_BŵB̂)")
        
        x_Bŵ += v_Bŵ*CGFloat(duration)
        v_Bŵ += fullEffect.force/M_boat*CGFloat(duration)
        
        θ_BŵB̂ += ω_BŵB̂*CGFloat(duration)
        ω_BŵB̂ += fullEffect.torque/I_boat*CGFloat(duration)
        
        self.tiller?.zRotation = θ_rB̂
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
    let boatI: CGVector3 // kg*m2?
}

struct BoatEffect {
    var force: CGVector3
    var torque: CGVector3
    static let zero: BoatEffect = BoatEffect(force: CGVector3.zero, torque: CGVector3.zero)
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
    var θx: CGFloat { return CGFloat(atan2(self.z, self.y)).normalizedAngle() } // y toward z
    var θy: CGFloat { return CGFloat(atan2(self.x, self.z)).normalizedAngle() } // z toward x
    var θz: CGFloat { return CGFloat(atan2(self.y, self.x)).normalizedAngle() } // x toward y
    var mag: CGFloat { return pow(self.mag2, 1/2) }
    var mag2: CGFloat { return pow(x, 2) + pow(y, 2) + pow(z, 2) }
    static let zero: CGVector3 = CGVector3(x: 0, y: 0, z: 0)
    
    static func + (left: CGVector3, right: CGVector3) -> CGVector3 {
        return CGVector3(x: left.x+right.x, y: left.y+right.y, z: left.z+right.z)
    }
    static func - (left: CGVector3, right: CGVector3) -> CGVector3 {
        return CGVector3(x: left.x-right.x, y: left.y-right.y, z: left.z-right.z)
    }
    static prefix func - (input: CGVector3) -> CGVector3 {
        return CGVector3(x: -input.x, y: -input.y, z: -input.z)
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
    static func * (left: CGVector3, right: CGFloat) -> CGVector3 {
        return CGVector3(x: left.x*right, y: left.y*right, z: left.z*right)
    }
    static func * (left: CGFloat, right: CGVector3) -> CGVector3 {
        return right*left
    }
    static func / (left: CGVector3, right: CGVector3) -> CGVector3 {
        return CGVector3(x: left.x/right.x, y: left.y/right.y, z: left.z/right.z)
    }
    static func / (left: CGVector3, right: CGFloat) -> CGVector3 {
        return CGVector3(x: left.x/right, y: left.y/right, z: left.z/right)
    }
    static func ⋅ (left: CGVector3, right: CGVector3) -> CGFloat {
        return left.x*right.x + left.y*right.y + left.z*right.z
    }
    
    func rotatedBy(transform θ_t: CGVector3) -> CGVector3 {
        let rotatedInZ = CGVector3(x: self.x*cos(θ_t.z) - self.y*sin(θ_t.z), y: self.x*sin(θ_t.z) + self.y*cos(θ_t.z), z: self.z)
        let rotatedInZY = CGVector3(x: rotatedInZ.x*cos(θ_t.y) + rotatedInZ.z*sin(θ_t.y), y: rotatedInZ.y, z: -rotatedInZ.x*sin(θ_t.y) + rotatedInZ.z*cos(θ_t.y))
        let rotatedInZYX = CGVector3(x: rotatedInZY.x, y: rotatedInZY.y*cos(θ_t.x) - rotatedInZY.z*sin(θ_t.x), z: rotatedInZY.y*sin(θ_t.x) + rotatedInZY.z*cos(θ_t.x))
        return rotatedInZYX
    }
    
    func torqueFromApplyingAtLocation(r: CGVector3) -> CGVector3 {
        return CGVector3(x: r.y*self.z - r.z*self.y, y: r.z*self.x - r.x*self.z, z: r.x*self.y - r.y*self.x)
    }
    
}
