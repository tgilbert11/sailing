//
//  Sloop.swift
//  sailing
//
//  Created by Taylor H. Gilbert on 7/12/17.
//  Copyright © 2017 Taylor H. Gilbert. All rights reserved.
//

import Foundation
import SpriteKit

class Sloop: Catboat {
    init(blueprint: SloopBlueprint) {
        super.init(blueprint: blueprint.catboatBlueprint)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func applyBoatEffect(effect: BoatEffect, duration: TimeInterval) {
        super.applyBoatEffect(effect: effect, duration: duration)
    }
    
}

struct SloopBlueprint {
    let catboatBlueprint: CatboatBlueprint
}
