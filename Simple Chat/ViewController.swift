//
//  ViewController.swift
//  Simple Chat
//
//  Created by M. Syulhan Al Ghofany on 03/10/24.
//

import UIKit
import SnapKit
import FirebaseFirestore
import FirebaseStorage
import AVFoundation

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var tableView: UITableView!
    var messageInputBar: UIView!
    var sendButton: UIButton!
    var micButton: UIButton!
    var messageTextField: UITextField!
    var messages: [(message: String, timestamp: Timestamp, isVoiceMessage: Bool, voiceURL: URL?)] = []
    var db: Firestore!
    var listener: ListenerRegistration?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        db = Firestore.firestore()
        setupViews()
        observeMessages()
        setupAudioSession()
    }
    
    func setupViews() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        messageInputBar = UIView()
        messageInputBar.backgroundColor = .lightGray
        view.addSubview(messageInputBar)
        
        messageTextField = UITextField()
        messageTextField.borderStyle = .roundedRect
        messageInputBar.addSubview(messageTextField)
        
        sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        messageInputBar.addSubview(sendButton)
        
        micButton = UIButton(type: .system)
        micButton.setTitle("Mic", for: .normal)
        micButton.addTarget(self, action: #selector(handleMicButton), for: .touchUpInside)
        messageInputBar.addSubview(micButton)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(messageInputBar.snp.top)
        }
        
        messageInputBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(50)
        }
        
        messageTextField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalTo(messageInputBar)
            make.right.equalTo(sendButton.snp.left).offset(-10)
            make.height.equalTo(40)
        }
        
        sendButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(messageInputBar)
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
        
        micButton.snp.makeConstraints { make in
            make.right.equalTo(sendButton.snp.left).offset(-10)
            make.centerY.equalTo(messageInputBar)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
    }
    
    func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Recording permission granted")
                    } else {
                        print("Recording permission denied")
                    }
                }
            }
        } catch {
            print("Failed to setup recording session: \(error)")
        }
    }
    
    func observeMessages() {
        listener = db.collection("messages").order(by: "timestamp", descending: false).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening for messages: \(error)")
            } else {
                self.messages = snapshot?.documents.compactMap { doc in
                    guard let message = doc.get("message") as? String,
                          let timestamp = doc.get("timestamp") as? Timestamp,
                          let isVoiceMessage = doc.get("isVoiceMessage") as? Bool else {
                        return nil
                    }
                    
                    if isVoiceMessage {
                        // Untuk pesan suara, pastikan voiceURLString ada dan dapat dikonversi ke URL
                        if let voiceURLString = doc.get("voiceURL") as? String,
                           let voiceURL = URL(string: voiceURLString) {
                            return (message, timestamp, isVoiceMessage, voiceURL)
                        } else {
                            return nil
                        }
                    } else {
                        // Untuk pesan teks, voiceURL bisa diabaikan
                        return (message, timestamp, isVoiceMessage, nil)
                    }
                } ?? []
                
                self.tableView.reloadData()
                self.scrollToBottom()
            }
        }
    }
    
    @objc func sendMessage() {
        if let message = messageTextField.text, !message.isEmpty {
            db.collection("messages").addDocument(data: [
                "message": message,
                "timestamp": FieldValue.serverTimestamp(),
                "isVoiceMessage": false,
                "voiceURL": nil
            ]) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self.messageTextField.text = ""
                    }
                }
            }
        }
    }
    
    @objc func handleMicButton() {
        if !isRecording {
            startRecording()
        } else {
            finishRecording()
        }
    }
    
    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: getDocumentsDirectory().appendingPathComponent("recording.m4a"), settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            isRecording = true
            micButton.setTitle("Stop", for: .normal)
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func finishRecording() {
        audioRecorder.stop()
        isRecording = false
        micButton.setTitle("Mic", for: .normal)
        uploadAudio()
    }
    
    func uploadAudio() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let storageRef = Storage.storage().reference().child("voice_notes/\(UUID().uuidString).m4a")
        
        storageRef.putFile(from: audioFilename, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload audio: \(error)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error)")
                    return
                }
                
                guard let downloadURL = url else { return }
                print("Download URL: \(downloadURL)")
                self.saveVoiceNoteToFirestore(downloadURL: downloadURL.absoluteString)
            }
        }
    }
    
    func saveVoiceNoteToFirestore(downloadURL: String) {
        db.collection("messages").addDocument(data: [
            "message": "",
            "timestamp": FieldValue.serverTimestamp(),
            "isVoiceMessage": true,
            "voiceURL": downloadURL
        ]) { error in
            if let error = error {
                print("Error sending voice note: \(error)")
            } else {
                print("Voice note sent successfully")
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func scrollToBottom() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChatTableViewCell
        
        print("dataaa: \(messages[indexPath.row])")
        cell.selectionStyle = .none
        cell.playPauseButton.addTarget(self, action: #selector(playPauseTapped(_:)), for: .touchUpInside)
        
        if messages[indexPath.row].isVoiceMessage {
            cell.configure(with: "Voice Note", timestamp: messages[indexPath.row].timestamp, isVoiceMessage: true, voiceURL: messages[indexPath.row].voiceURL)
            cell.playPauseButton.tag = indexPath.row
            
        } else {
            cell.configure(with: messages[indexPath.row].message, timestamp: messages[indexPath.row].timestamp, isVoiceMessage: false, voiceURL: nil)
        }
        
        return cell
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("aaaaaa")
//    }
    
    @objc func playPauseTapped(_ sender: UIButton) {
        print("aaaaaa")
//        guard let player = audioPlayer else { return }
//        
//        if isPlaying {
//            player.pause()
//            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
//            stopWaveAnimation()
//        } else {
//            player.play()
//            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
//            startWaveAnimation()
//        }
//        isPlaying.toggle()
    }
}
