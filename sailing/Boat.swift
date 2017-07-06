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

class Boat: SKSpriteNode {
    let g: CGFloat = 9.806 // m/s2
    let ρ_air: CGFloat = 1.225 // kg/m3
    let ρ_water: CGFloat = 1000 // kg/m3
    
    var x_Bŵ = CGVector(dx: 0, dy: 0) // m
    var Δx_Bŵ = CGVector(dx: 0, dy: 0) // Δm/s, SHOULD BE PRIVATE
    var v_Bŵ = CGVector(dx: 0, dy: 0) // m/s
    var θ_Bŵ: CGFloat = 0 // radians
    var θ_bbŵ: CGFloat = 0 // radians
    var Δθ_bbŵ: CGFloat = 0 // Δradians
    
    func printLocation() {
        print (self.position)
    }
    
    
    
}
