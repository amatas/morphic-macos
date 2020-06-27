//
//  ContrastUIAutomation.swift
//  MorphicSettings
//
//  Created by Owen Shaw on 6/26/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

import Foundation
import MorphicCore
import OSLog

private let logger = OSLog(subsystem: "MorphicSettings", category: "ContrastUIAutomation")


public class ContrastUIAutomation: AccessibilityUIAutomation{
    
    public override func apply(_ value: Interoperable?, completion: @escaping (Bool) -> Void) {
        guard let checked = value as? Bool else{
            os_log(.error, log: logger, "Passed non-boolean value")
            completion(false)
            return
        }
        showAccessibilityDisplayPreferences(tab: "Display"){
            accessibility in
            guard let accessibility = accessibility else{
                completion(false)
                return
            }
            guard let checkbox = accessibility.checkbox(titled: "Increase contrast") else{
                os_log(.error, log: logger, "Failed to find contrast checkbox")
                completion(false)
                return
            }
            guard checkbox.setChecked(checked) else{
                os_log(.error, log: logger, "Failed to press contrast checkbox")
                completion(false)
                return
            }
            if !checked{
                if let transparencyCheckbox = accessibility.checkbox(titled: "Reduce transparency"){
                    if !transparencyCheckbox.uncheck(){
                        os_log(.info, log: logger, "Failed to uncheck reduce transparency when turning off high contrast")
                    }
                }
            }
            completion(true)
        }
    }
    
}
