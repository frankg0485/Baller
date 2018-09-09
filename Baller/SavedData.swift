//
//  SavedData.swift
//  Baller
//
//  Created by Frank Gao on 9/9/18.
//  Copyright © 2018 Frank Gao. All rights reserved.
//

import Foundation
import UIKit

class SavedData {
    static let defaults = UserDefaults.standard
    static let highScore = "highScore"

    static func getHighScore() -> Int {
        return defaults.integer(forKey: highScore)
    }

    static func setHighScore(score: Int) {
        defaults.set(score, forKey: highScore)
    }
}
