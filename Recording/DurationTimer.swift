//
//  Timer.swift
//  Recording
//
//  Created by Lauren White on 9/9/19.
//  Copyright © 2019 Lauren White. All rights reserved.
//

import Foundation

class DurationTimer {
    var startTime: CFAbsoluteTime?
    var endTime: CFAbsoluteTime?
    
    var duration: TimeInterval? {
        if let startTime = startTime, let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
    
    func start() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func stop() {
        endTime = CFAbsoluteTimeGetCurrent()
    }
    
    public static func formatTime(interval: Double) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.collapsesLargestUnit = false
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        return formatter.string(from: TimeInterval(interval))
    }
}
