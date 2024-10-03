//
//  ChatTableViewCell.swift
//  Simple Chat
//
//  Created by M. Syulhan Al Ghofany on 03/10/24.
//

import UIKit
import SnapKit
import FirebaseFirestore
import AVFoundation

class ChatTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.backgroundColor = .orange
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .lightGray
        label.backgroundColor = .green
        return label
    }()
    
    let bubbleBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue
        view.layer.cornerRadius = 15
        view.isUserInteractionEnabled = true
        return view
    }()
    
    let playPauseButton = UIButton()
    let waveformView = UIView()
    let durationLabel = UILabel()
    
    var audioPlayer: AVAudioPlayer?
    var isPlaying = false
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupChild()
        setupUI()
        setupConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupChild() {
        addSubview(bubbleBackgroundView)
        bubbleBackgroundView.addSubview(messageLabel)
        addSubview(timeLabel)
        bubbleBackgroundView.addSubview(playPauseButton)
//        bubbleBackgroundView.addSubview(waveformView)
//        bubbleBackgroundView.addSubview(durationLabel)
    }
    
    private func setupUI() {
//        let tapgest = UITapGestureRecognizer(target: self, action: #selector(playPauseTapped(_:)))
//        bubbleBackgroundView.addGestureRecognizer(tapgest)
//        
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = .lightGray
        
        // Setup playPauseButton
        playPauseButton.setTitle("Tes", for: .normal)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
//        playPauseButton.addTarget(self, action: #selector(playPauseTapped(_:)), for: .touchUpInside) // Menggunakan addTarget
        playPauseButton.backgroundColor = .red
        
        // Setup waveformView
        waveformView.backgroundColor = .lightGray
        
        // Setup durationLabel
        durationLabel.text = "00:00"
        durationLabel.textColor = .white
        durationLabel.font = UIFont.systemFont(ofSize: 12)
        durationLabel.isUserInteractionEnabled = true
    }
    
    private func setupConstraint() {
        bubbleBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.greaterThanOrEqualToSuperview().offset(50)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10).priority(.high)
            make.height.equalTo(50)
            make.width.equalTo(120)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(bubbleBackgroundView.snp.trailing).offset(5)
            make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
        }
        
        // Tombol play/pause, waveform, dan durasi untuk voice message
        playPauseButton.snp.makeConstraints { make in
            make.leading.equalTo(bubbleBackgroundView).offset(10)
            make.centerY.equalTo(bubbleBackgroundView)
            make.height.equalTo(40)
            make.width.equalTo(100)
        }
        
//        waveformView.snp.makeConstraints { make in
//            make.leading.equalTo(playPauseButton.snp.trailing).offset(10)
//            make.centerY.equalTo(bubbleBackgroundView)
//            make.height.equalTo(20)
//            make.width.equalTo(100)
//        }
//        
//        durationLabel.snp.makeConstraints { make in
//            make.leading.equalTo(waveformView.snp.trailing).offset(10)
//            make.centerY.equalTo(bubbleBackgroundView)
//            make.trailing.equalTo(bubbleBackgroundView).offset(-10)
//        }
    }
    
    func configure(with message: String, timestamp: Timestamp, isVoiceMessage: Bool, voiceURL: URL?, isSender: Bool = true) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeString = dateFormatter.string(from: timestamp.dateValue())
        timeLabel.text = timeString
        
        if isVoiceMessage, let voiceURL = voiceURL {
            messageLabel.isHidden = true
            playPauseButton.isHidden = false
            waveformView.isHidden = false
            durationLabel.isHidden = false
            
            downloadVoiceMessage(from: voiceURL) { [weak self] localURL in
                guard let strongSelf = self, let localURL = localURL else { return }
                
                do {
                    strongSelf.audioPlayer = try AVAudioPlayer(contentsOf: localURL)
                    strongSelf.audioPlayer?.prepareToPlay()
                    DispatchQueue.main.async {
                        strongSelf.durationLabel.text = strongSelf.formatTime(strongSelf.audioPlayer?.duration ?? 0)
                    }
                } catch {
                    print("Failed to load audio file: \(error)")
                }
            }
        } else {
            messageLabel.isHidden = false
            playPauseButton.isHidden = true
            waveformView.isHidden = true
            durationLabel.isHidden = true
            messageLabel.text = message
        }
        
//        if isSender {
//            bubbleBackgroundView.backgroundColor = .systemBlue
//            messageLabel.textColor = .white
//            
//            bubbleBackgroundView.snp.remakeConstraints { make in
//                make.top.equalToSuperview().offset(10)
//                make.trailing.equalToSuperview().offset(-20)
//                make.leading.greaterThanOrEqualToSuperview().offset(50)
//                make.bottom.equalToSuperview().offset(-10).priority(.high)
//                make.height.equalTo(50)
//            }
//            
//            timeLabel.snp.remakeConstraints { make in
//                make.trailing.equalTo(bubbleBackgroundView.snp.leading).offset(-5)
//                make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
//            }
//        } else {
//            bubbleBackgroundView.backgroundColor = .lightGray
//            messageLabel.textColor = .black
//            
//            bubbleBackgroundView.snp.remakeConstraints { make in
//                make.top.equalToSuperview().offset(10)
//                make.leading.equalToSuperview().offset(20)
//                make.trailing.lessThanOrEqualToSuperview().offset(-50)
//                make.bottom.equalToSuperview().offset(-10).priority(.high)
//            }
//            
//            timeLabel.snp.remakeConstraints { make in
//                make.trailing.equalTo(bubbleBackgroundView.snp.leading).offset(-5)
//                make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
//            }
//        }
    }
    
    func downloadVoiceMessage(from url: URL, completion: @escaping (URL?) -> Void) {
        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                print("Failed to download audio: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            completion(localURL)
        }
        downloadTask.resume()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
//    @objc func playPauseTapped(_ sender: UIView) {
//        print("aaaaaa")
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
//    }
    
    private func startWaveAnimation() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.waveformView.transform = CGAffineTransform(scaleX: 1, y: 1.5)
        }, completion: nil)
    }
    
    private func stopWaveAnimation() {
        waveformView.layer.removeAllAnimations()
        waveformView.transform = .identity
    }
}


// Fungsi untuk mengatur tampilan bubble berdasarkan pengirim
//    func configure(with message: String, timestamp: Timestamp, isVoiceMessage: Bool, voiceURL: URL?, isSender: Bool = true) {
//        messageLabel.text = message
//
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "HH:mm"
//
//        let timeString = dateFormatter.string(from: timestamp.dateValue())
//        timeLabel.text = timeString
//
//        if isSender { // Jika pengirim adalah pengguna
//            bubbleBackgroundView.backgroundColor = .systemBlue
//            messageLabel.textColor = .white
//
//            bubbleBackgroundView.snp.remakeConstraints { make in
//                make.top.equalToSuperview().offset(10)
//                make.trailing.equalToSuperview().offset(-20) // Bubble di kanan
//                make.leading.greaterThanOrEqualToSuperview().offset(50)
//                make.bottom.equalToSuperview().offset(-10).priority(.high)
//            }
//
//            timeLabel.snp.remakeConstraints { make in
//                make.trailing.equalTo(bubbleBackgroundView.snp.leading).offset(-5)
//                make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
//            }
//
//        } else { // Jika pengirim adalah penerima
//            bubbleBackgroundView.backgroundColor = .lightGray
//            messageLabel.textColor = .black
//
//            bubbleBackgroundView.snp.remakeConstraints { make in
//                make.top.equalToSuperview().offset(10)
//                make.leading.equalToSuperview().offset(20) // Bubble di kiri
//                make.trailing.lessThanOrEqualToSuperview().offset(-50)
//                make.bottom.equalToSuperview().offset(-10).priority(.high)
//            }
//
//            timeLabel.snp.remakeConstraints { make in
//                make.trailing.equalTo(bubbleBackgroundView.snp.leading).offset(-5)
//                make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
//            }
//        }
//    }
//}
