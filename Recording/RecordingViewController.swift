//
//  RecordingViewController.swift
//  Recording
//
//  Created by Lauren White on 9/5/19.
//  Copyright © 2019 Lauren White. All rights reserved.
//
import AVFoundation
import Foundation
import UIKit

class RecordingViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource {

    // MARK - Variables
    
    // Database variables
    let database = RecordingsDatabase()
    var recordings: [Recording] { return database.getRecordings() }
    var count: Int { return database.countRecordings() }

    // Recording variables
    var newRecording: Recording?
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var stopTimer: DurationTimer = DurationTimer()
    var isRecording: Bool = false

    // Player variables
    var audioPlayer: AVAudioPlayer?
    var audioEngine: AVAudioEngine?
    var audioPlayerNode: AVAudioPlayerNode?
    var isPlaying: Bool = false
    var isPaused: Bool = false
    
    // File Manager Convenience variables
    class var docDirectoryPath: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    class var numberOfDocumentsInDirectory: Int {
        let fileURLs = try! FileManager.default.contentsOfDirectory(at: docDirectoryPath, includingPropertiesForKeys: nil)
        return fileURLs.count
    }
    
    class func generateFilePath(fileName: String) -> URL {
        return docDirectoryPath.appendingPathComponent(fileName)
    }
    
    
    // MARK - UI Outlets
    @IBOutlet var recordingsTableView: UITableView!
    @IBOutlet var recordStopButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        recordingsTableView.delegate = self
        recordingsTableView.dataSource = self
        
        configureUI()
        setupAudio()
    }

    private func configureUI() {
        playButton.setImage(UIImage(named: "play"), for: .normal)
        deleteButton.setImage(UIImage(named: "trash"), for: .normal)
        configurePlayUISettings()
    }
    
    func configurePlayUISettings() {
        let enable = !isRecording && recordingsTableView.indexPathForSelectedRow != nil
        playButton.isEnabled = enable
        deleteButton.isEnabled = enable
    }
    
    
    // MARK - Button actions
    
    @IBAction func recordStopButtonPressed(_ sender: Any) {
        if(isRecording) {
            // If already recording, then stop recording
            recordStopButton.setImage(UIImage(named: "Record"), for: .normal)
            isRecording = false
            stopRecording(success: true)
        } else {
            // If not recording, then start recording
            recordStopButton.setImage(UIImage(named: "Stop"), for: .normal)
            isRecording = true
            startRecording()
        }
        configurePlayUISettings()
    }
    
    @IBAction func playPauseButtonPressed(_ sender: Any) {
        if(isPlaying) {
            pausePlayback()
            playButton.setImage(UIImage(named: "play"), for: .normal)
            isPlaying = false
        } else {
            if let selectedIndexPath = recordingsTableView.indexPathForSelectedRow {
                if isPaused {
                    resumePlayback()
                } else {
                    startPlayback(index: selectedIndexPath.row)
                }
                playButton.setImage(UIImage(named: "pause"), for: .normal)
                isPlaying = true
            }
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        if let selectedIndexPath = recordingsTableView.indexPathForSelectedRow {
            let filePath = RecordingViewController.generateFilePath(fileName: recordings[selectedIndexPath.row].fileName)
            do {
                try FileManager.default.removeItem(at: filePath)
            } catch {
                print("Could not delete file")
            }
            database.removeRecording(at: selectedIndexPath.row)
            reloadTableViewData()
            configurePlayUISettings()
        }
    }
    
    // MARK - Table View Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordingcell", for: indexPath) as! RecordingCell
        let name = recordings[indexPath.row].name
        let time = DurationTimer.formatTime(interval: recordings[indexPath.row].time)
        cell.configure(name: name, time: time ?? "N/A")
        return cell
    }
    
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(isPlaying || isPaused) {
            finishPlayback()
        }
        configurePlayUISettings()
    }
    
    func reloadTableViewData() {
        recordingsTableView.reloadData()
    }
}




// MARK - Custom TableViewCell class
class RecordingCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(name: String, time: String) {
        nameLabel.text = name
        timeLabel.text = time
    }
}
