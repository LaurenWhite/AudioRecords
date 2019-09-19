//
//  PlaybackSupport.swift
//  Recording
//
//  Created by Lauren White on 9/17/19.
//  Copyright © 2019 Lauren White. All rights reserved.
//

import Foundation
import AVFoundation
import Foundation
import UIKit

extension RecordingViewController {
    
    func nameRecording() {
        let ac = UIAlertController(title: "Enter name for recording", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.textFields?[0].placeholder = "Recording #\(database.absCount + 1)"
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
            let submission = ac.textFields![0]
            self.newRecording?.name = submission.text?.count == 0 ? submission.placeholder! : submission.text!
            if let newRecording = self.newRecording {
                self.database.addRecording(newRecording: newRecording)
            }
            self.newRecording = nil
            self.configurePlayUISettings()
            self.recordingsTableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { _ in
            do {
                let filePath = RecordingViewController.generateFilePath(fileName: self.newRecording!.fileName)
                try FileManager.default.removeItem(at: filePath)
            } catch {
                print("Could not delete file")
            }
            self.newRecording = nil
        }
        
        ac.addAction(submitAction)
        ac.addAction(cancelAction)
        present(ac, animated: true)
    }
    
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
    }
}
