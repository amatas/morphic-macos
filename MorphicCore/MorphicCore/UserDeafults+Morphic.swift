//
//  UserDeafults+Morphic.swift
//  MorphicCore
//
//  Created by Owen Shaw on 2/25/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation

public extension UserDefaults {
    static var morphic = UserDefaults(suiteName: "org.raisingthefloor.MorphicLite")!
}

public extension String{
    static var morphicDefaultsKeyUserIdentifier = "userIdentifier"
}
