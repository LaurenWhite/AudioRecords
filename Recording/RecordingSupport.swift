//
//  RecordingSupport.swift
//  Recording
//
//  Created by Lauren White on 9/17/19.
//  Copyright © 2019 Lauren White. All rights reserved.
//

import Foundation
import AVFoundation

extension RecordingViewController {
    
    func setupAudio() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        print("Acccess to microphone denied")
                    }
                }
            }
        } catch {
            print("Could not set up recording environment, will not be able to record")
        }
    }
    
    func startRecording() {
        stopTimer.start()
        let fileName = "recording\(database.absCount).m4a"
        let audioFilePath = RecordingViewController.generateFilePath(fileName: fileName)
        print(audioFilePath.absoluteString)
        newRecording = Recording(name: "name", time: 0, fileName: fileName)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch {
            stopRecording(success: false)
        }
    }
    
    func stopRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        stopTimer.stop()
        
        guard success else {
            print("Failure to capture recording")
            newRecording = nil
            return
        }
        if let duration = stopTimer.duration {
            newRecording?.time = duration
        }
        nameRecording()
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording(success: false)
        }
    }
}
