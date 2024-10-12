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

class ChatViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    private let myArray: NSArray = ["First", "Second", "Third"]
    var myTableView = UITableView()
    
    var messageInputBar = UIView()
    var sendButton = UIButton()
    var micButton = UIButton()
    var cameraButton = UIButton()
    var messageTextField = UITextField()
    var waveformView = UIView()
    var durationLabel = UILabel()
    var activityIndicator = UIActivityIndicatorView(style: .medium)
    var messages: [(message: String, timestamp: Timestamp, isVoiceMessage: Bool, voiceURL: URL?)] = []
    var db: Firestore!
    var listener: ListenerRegistration?
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var isRecording = false
    var timer: Timer?
    var maxRecordingDuration: TimeInterval = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        db = Firestore.firestore()
        
        setupChilds()
        setupViews()
        setupConstraint()
        
        observeMessages()
        setupAudioSession()
    }
    
    func setupChilds() {
        view.addSubview(myTableView)
        
        view.addSubview(messageInputBar)
        messageInputBar.addSubview(messageTextField)
        messageInputBar.addSubview(sendButton)
        messageInputBar.addSubview(micButton)
        
        messageInputBar.addSubview(waveformView) // Tambahkan view gelombang
        messageInputBar.addSubview(durationLabel) // Tambahkan label durasi
        messageInputBar.addSubview(activityIndicator)
    }
    
    func setupViews() {
        myTableView.separatorStyle = .none
        myTableView.register(TextChatCell.self, forCellReuseIdentifier: "TextCell")
        myTableView.register(AudioChatCell.self, forCellReuseIdentifier: "AudioCell")
        myTableView.dataSource = self
        myTableView.delegate = self
        
        messageInputBar.backgroundColor = .lightGray
        
        messageTextField.borderStyle = .roundedRect
        
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .black
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = .black
        micButton.addTarget(self, action: #selector(handleMicButton), for: .touchUpInside)
        
        waveformView.backgroundColor = .clear
        durationLabel.textColor = .black
        durationLabel.font = UIFont.systemFont(ofSize: 12)
        durationLabel.isHidden = true
        
        activityIndicator.hidesWhenStopped = true
    }
    
    func setupConstraint() {
        // Menggunakan SnapKit untuk mengatur constraint
        messageInputBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(50)
        }
        
        myTableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(messageInputBar.snp.top)
            make.left.right.equalToSuperview()
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
        
        waveformView.snp.makeConstraints { make in
            make.left.equalTo(micButton.snp.right).offset(10)
            make.centerY.equalTo(messageInputBar)
            make.right.equalTo(durationLabel.snp.left).offset(-10)
            make.height.equalTo(15)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.right.equalTo(messageInputBar).offset(-10)
            make.centerY.equalTo(messageInputBar)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(messageInputBar)
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
                
                self.myTableView.reloadData()
                self.scrollToBottom()
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
            myTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if messages[indexPath.row].isVoiceMessage {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AudioCell", for: indexPath) as! AudioChatCell
            cell.selectionStyle = .none
            cell.configure(with: "Voice Note", timestamp: messages[indexPath.row].timestamp, voiceURL: messages[indexPath.row].voiceURL)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath) as! TextChatCell
            cell.selectionStyle = .none
            cell.configure(with: messages[indexPath.row].message, timestamp: messages[indexPath.row].timestamp)
            
            return cell
        }
    }
}

// MARK: - RECORD VN
extension ChatViewController {
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
            
            micButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            messageTextField.isHidden = true
            waveformView.isHidden = false // Tampilkan waveform
            durationLabel.isHidden = false // Tampilkan durasi
            durationLabel.text = "0s"
            activityIndicator.stopAnimating()
            
            // Mulai timer untuk durasi
            startTimer()
            
            // Batas waktu rekaman
            Timer.scheduledTimer(timeInterval: maxRecordingDuration, target: self, selector: #selector(finishRecording), userInfo: nil, repeats: false)
            
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    @objc func finishRecording() {
        audioRecorder.stop()
        isRecording = false
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        
        // Reset tampilan
        waveformView.isHidden = true
        durationLabel.isHidden = true
        messageTextField.isHidden = false // Tampilkan kembali textField
        
        uploadAudio() // Unggah audio setelah selesai merekam
        stopTimer() // Hentikan timer
    }
    
    // Timer untuk durasi rekaman
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let currentTime = self.audioRecorder?.currentTime {
                let seconds = Int(currentTime)
                self.durationLabel.text = "\(seconds)s"
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}

// MARK: - SAVE TO FIREBASE
extension ChatViewController {
    // MARK: - TEKS
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
    
    // MARK: - AUDIO
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
}

// MARK: - SAVE TO STORAGE
extension ChatViewController {
    
    // MARK: - AUDIO
    func uploadAudio() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let storageRef = Storage.storage().reference().child("voice_notes/\(UUID().uuidString).m4a")
        
        storageRef.putFile(from: audioFilename, metadata: nil) { [weak self] metadata, error in
            
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            
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
}
