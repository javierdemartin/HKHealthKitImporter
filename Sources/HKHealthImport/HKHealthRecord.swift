//
//  File.swift
//  
//
//  Created by Javier de Martín Gil on 15/1/21.
//

import Foundation
import HealthKit

class HKHealthRecord: CustomStringConvertible {
    var description: String = ""
    
    var type: String = String()
    var value: Double = 0
    var unit: String?
    var sourceName: String = String()
    var sourceVersion: String = String()
    var startDate: Date = Date()
    var endDate: Date = Date()
    var creationDate: Date = Date()

    // Workout data
    var activityType: HKWorkoutActivityType? = HKWorkoutActivityType(rawValue: 0)
    var totalEnergyBurned: Double = 0
    var totalDistance: Double = 0
    var totalEnergyBurnedUnit: String = String()
    var totalDistanceUnit: String = String()

    var metadata: [String: Any]?
    
    var device: HKDevice?
    
    var associatedGpxUrl: URL?
    
    // MARK: Workout data
    
    /// https://developer.apple.com/documentation/healthkit/hkmetadatakeytimezone#
    var timeZone: TimeZone?
    
    /// https://developer.apple.com/documentation/healthkit/hkworkoutevent#
    var workoutEvent: [MyHKWorkoutEvent] = []
}

struct MyHKWorkoutEvent {
    let type: MyHKWorkoutEventType
    let date: Date
}

enum MyHKWorkoutEventType: String {
    case pause = "HKWorkoutEventTypePause"
    case resume = "HKWorkoutEventTypeResume"
}
