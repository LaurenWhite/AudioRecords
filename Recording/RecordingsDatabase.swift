//
//  RecordingsDatabase.swift
//  Recording
//
//  Created by Lauren White on 9/16/19.
//  Copyright © 2019 Lauren White. All rights reserved.
//

import Foundation

private var recordings: [Recording] = RecordingsDatabase.loadSavedRecordings()
private let recordingKey = "recordings.key"

private var absoluteCount = RecordingsDatabase.loadAbsoluteCount()
private let absCountKey = "abs.count.key"

struct Recording {
    var name: String
    var time: Double
    let url: URL
}

class RecordingsDatabase {
    
    func countRecordings() -> Int {
        return recordings.count
    }
    
    func getRecordings() -> [Recording] {
        return recordings
    }
    
    var absCount: Int {
        return absoluteCount
    }
    
    func addRecording(newRecording: Recording) {
        recordings.append(newRecording)
        absoluteCount += 1
        saveRecordings()
        saveAbsoluteCount()
    }
    
    func removeRecording(at index: Int) {
        guard index > 0, index < recordings.count else { return }
        recordings.remove(at: index)
        saveRecordings()
    }
    
    func saveRecordings() {
        var data: [[String:Any]] = []
        for recording in recordings {
            let recordingData: [String:Any] = [
                "name" : recording.name,
                "time" : recording.time,
                "url" : recording.url.path
            ]
            data.append(recordingData)
        }
        UserDefaults.standard.set(data, forKey: recordingKey)
    }
    
    func saveAbsoluteCount() {
        UserDefaults.standard.set(absoluteCount, forKey: absCountKey)
    }
    
    static func loadSavedRecordings() -> [Recording] {
        let savedData = UserDefaults.standard.array(forKey: recordingKey) as? [[String:AnyObject]] ?? []
        var array: [Recording] = []
        for recordingData in savedData {
            if let recordingName = recordingData["name"] as? String,
                let recordingTime = recordingData["time"] as? Double,
                let recordingURL = recordingData["url"] as? String {
                let url = URL(fileURLWithPath: recordingURL)
                array.append(Recording(name: recordingName, time: recordingTime, url: url))
            }
        }
        return array
    }
    
    static func loadAbsoluteCount() -> Int {
        return UserDefaults.standard.integer(forKey: absCountKey)
    }
}
