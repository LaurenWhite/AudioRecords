//
//  PlaybackSupport.swift
//  Recording
//
//  Created by Lauren White on 9/17/19.
//  Copyright © 2019 Lauren White. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

extension RecordingViewController {
    
    func startPlayback(index: Int) {
        do {
            audioEngine = AVAudioEngine()
            audioPlayerNode = AVAudioPlayerNode()
            
            guard let audioEngine = audioEngine, let audioPlayerNode = audioPlayerNode else { return }
            
            audioEngine.attach(audioPlayerNode)
            audioPlayerNode.stop()
            
            let filePath = RecordingViewController.generateFilePath(fileName: recordings[index].fileName)
            let audioFile = try AVAudioFile(forReading: filePath)
            audioEngine.connect(audioPlayerNode, to: audioEngine.outputNode, format: audioFile.processingFormat)
            audioPlayerNode.scheduleFile(audioFile, at: nil, completionHandler: {
                print("Finished!")
                DispatchQueue.main.async {
                    self.finishPlayback()
                }
            })
            
            do {
                try audioEngine.start()
            } catch {
                print("Failure to start audio engine")
                return
            }
            
            audioPlayerNode.play()
        } catch let error {
            print("Can't play the audio file failed with an error \(error.localizedDescription)")
        }
    }
    
    func resumePlayback() {
        audioPlayerNode?.play()
        isPaused = false
    }
    
    func pausePlayback() {
        audioPlayerNode?.pause()
        isPaused = true
    }
    
    func finishPlayback() {
        isPaused = false
        isPlaying = false
        playButton.setImage(UIImage(named: "play"), for: .normal)
        audioPlayerNode?.stop()
        audioEngine?.stop()
    }
}
