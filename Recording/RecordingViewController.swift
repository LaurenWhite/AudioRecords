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
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("Error trying to set up recording session")
        }
    }
    
    var docDirectoryPath: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    var numberOfDocumentsInDirectory: Int {
        let fileURLs = try! FileManager.default.contentsOfDirectory(at: docDirectoryPath, includingPropertiesForKeys: nil)
        return fileURLs.count
    }
    
    private func configureUI() {
        playButton.setImage(UIImage(named: "play"), for: .normal)
        deleteButton.setImage(UIImage(named: "trash"), for: .normal)
        configurePlaySettings()
    }
    
    private func configurePlaySettings() {
        let enable = !isRecording && recordingsTableView.indexPathForSelectedRow != nil
        playButton.isEnabled = enable
        deleteButton.isEnabled = enable
    }
    
    
    // MARK - Buttons actions
    
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
        configurePlaySettings()
    }
    
    @IBAction func playPauseButtonPressed(_ sender: Any) {
        guard playButton.isEnabled else { return }
        if(isPlaying) {
            // stopPlayingRecording()
            playButton.setImage(UIImage(named: "play"), for: .normal)
            isPlaying = false
        } else {
            if let selectedIndexPath = recordingsTableView.indexPathForSelectedRow {
                playRecording(index: selectedIndexPath.row)
                playButton.setImage(UIImage(named: "pause"), for: .normal)
                isPlaying = true
            }
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        guard deleteButton.isEnabled else { return }
        if let selectedIndexPath = recordingsTableView.indexPathForSelectedRow {
            database.removeRecording(at: selectedIndexPath.row)
            reloadTableViewData()
        }
    }
    
    
    
    // MARK - Helper functions
    
    func startRecording() {
        stopTimer.start()
        let audioFilePath  = docDirectoryPath.appendingPathComponent("recording\(database.absCount).m4a")
        print(audioFilePath.absoluteString)
        newRecording = Recording(name: "name", time: 0, url: audioFilePath)
        
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
        if let duration = stopTimer.duration {
            newRecording?.time = duration
        }
        nameRecording()
    }
    
    func nameRecording() {
        let ac = UIAlertController(title: "Enter name for recording", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.textFields?[0].placeholder = "Recording #\(count)"
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
            let submission = ac.textFields![0]
            self.newRecording?.name = submission.text?.count == 0 ? submission.placeholder! : submission.text!
            if let newRecording = self.newRecording {
                self.database.addRecording(newRecording: newRecording)
            }
            self.newRecording = nil
            self.configurePlaySettings()
            self.recordingsTableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { _ in
            do {
                try FileManager.default.removeItem(at: self.newRecording!.url)
            } catch {
                print("Could not delete file")
            }
            self.newRecording = nil
        }
        
        ac.addAction(submitAction)
        ac.addAction(cancelAction)
        present(ac, animated: true)
    }
    
    func playRecording(index: Int) {
        do {
            audioEngine = AVAudioEngine()
            audioPlayerNode = AVAudioPlayerNode()
           
            guard let audioEngine = audioEngine, let audioPlayerNode = audioPlayerNode else { return }
            
            audioEngine.attach(audioPlayerNode)
            audioPlayerNode.stop()
            
            let audioFile = try AVAudioFile(forReading: recordings[index].url)
            audioEngine.connect(audioPlayerNode, to: audioEngine.outputNode, format: audioFile.processingFormat)
            audioPlayerNode.scheduleFile(audioFile, at: nil)
            
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
        configurePlaySettings()
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
