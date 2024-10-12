//
//  AudioChatCell.swift
//  Simple Chat
//
//  Created by M. Syulhan Al Ghofany on 04/10/24.
//

import UIKit
import SnapKit
import FirebaseFirestore
import AVFoundation

class AudioChatCell: UITableViewCell, AVAudioPlayerDelegate {

    let timeLabel = UILabel()
    let bubbleBackgroundView = UIView()
    let playPauseButton = UIButton()
    let waveformView = UIView()
    let durationLabel = UILabel()
    
    var audioPlayer: AVAudioPlayer?
    var isPlaying = false
    var timer: Timer?
    static var currentlyPlayingCell: AudioChatCell?
    var waveAnimationLayer: CAShapeLayer?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupChild()
        setupUI()
        setupConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupChild() {
        contentView.addSubview(bubbleBackgroundView)
        bubbleBackgroundView.addSubview(playPauseButton)
        bubbleBackgroundView.addSubview(waveformView)
        bubbleBackgroundView.addSubview(durationLabel)
        contentView.addSubview(timeLabel)
    }
    
    private func setupUI() {
        bubbleBackgroundView.backgroundColor = UIColor.systemBlue
        bubbleBackgroundView.layer.cornerRadius = 15
        
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        
        // Setup waveformView
        waveformView.backgroundColor = .white
//        waveformView.backgroundColor = .clear
        
        // Setup durationLabel
        durationLabel.text = "00:00"
        durationLabel.textColor = .white
        durationLabel.font = UIFont.systemFont(ofSize: 10)
        
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = .lightGray
    }
    
    private func setupConstraint() {
        bubbleBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10).priority(.high)
            make.height.equalTo(50)
            make.width.equalTo(180)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(bubbleBackgroundView.snp.leading).offset(-5)
            make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
        }
        
        // Tombol play/pause, waveform, dan durasi untuk voice message
        playPauseButton.snp.makeConstraints { make in
            make.leading.equalTo(bubbleBackgroundView).offset(10)
            make.centerY.equalTo(bubbleBackgroundView)
            make.height.equalTo(30)
            make.width.equalTo(30)
        }
        
        waveformView.snp.makeConstraints { make in
            make.trailing.equalTo(durationLabel.snp.leading).offset(-15)
            make.centerY.equalTo(bubbleBackgroundView)
            make.height.equalTo(15)
            make.width.equalTo(70)
        }

        durationLabel.snp.makeConstraints { make in
            make.bottom.equalTo(waveformView.snp.bottom)
            make.trailing.equalTo(bubbleBackgroundView).offset(-10)
        }
    }
    
    func configure(with message: String, timestamp: Timestamp, voiceURL: URL?, isSender: Bool = true) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeString = dateFormatter.string(from: timestamp.dateValue())
        
        timeLabel.text = timeString
        
        if let voiceURL = voiceURL {
            downloadVoiceMessage(from: voiceURL) { [weak self] localURL in
                guard let strongSelf = self, let localURL = localURL else { return }
                
                do {
                    strongSelf.audioPlayer = try AVAudioPlayer(contentsOf: localURL)
                    strongSelf.audioPlayer?.prepareToPlay()
                    strongSelf.audioPlayer?.delegate = strongSelf
                    DispatchQueue.main.async {
                        strongSelf.durationLabel.text = strongSelf.formatTime(strongSelf.audioPlayer?.duration ?? 0)
                        strongSelf.drawWaveform()
                    }
                } catch {
                    print("Failed to load audio file: \(error)")
                }
            }
        }
        
        if isSender {
            bubbleBackgroundView.backgroundColor = .systemBlue
            
            bubbleBackgroundView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.trailing.equalToSuperview().offset(-20)
                make.leading.greaterThanOrEqualToSuperview().offset(50)
                make.bottom.equalToSuperview().offset(-10).priority(.high)
                make.height.equalTo(50)
                make.width.equalTo(180)
            }
            
            timeLabel.snp.makeConstraints { make in
                make.trailing.equalTo(bubbleBackgroundView.snp.leading).offset(-5)
                make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
            }
        } else {
            bubbleBackgroundView.backgroundColor = .lightGray
            
            bubbleBackgroundView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.leading.greaterThanOrEqualToSuperview().offset(20)
                make.trailing.lessThanOrEqualToSuperview().offset(-20)
                make.bottom.equalToSuperview().offset(-10).priority(.high)
                make.height.equalTo(50)
                make.width.equalTo(180)
            }
            
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleBackgroundView.snp.trailing).offset(5)
                make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
            }
        }
    }
    
    @objc func didTapButton() {
        print("aaaaaaa")
        if AudioChatCell.currentlyPlayingCell != nil && AudioChatCell.currentlyPlayingCell != self {
            AudioChatCell.currentlyPlayingCell?.stopAudio()
        }
        
        AudioChatCell.currentlyPlayingCell = self
        
        guard let player = audioPlayer else { return }
        
        if isPlaying {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            stopWaveAnimation()
            stopTimer()
        } else {
            player.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            startWaveAnimation()
            startTimer()
        }
        
        isPlaying.toggle()
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
    
    private func drawWaveform() {
        guard let player = audioPlayer else { return }
        
        let path = UIBezierPath()
        let width = waveformView.bounds.width
        let height = waveformView.bounds.height
        
        // Create wave pattern
        let numberOfPoints = 50
        let amplitude: CGFloat = height / 2 * 0.8
        
        for i in 0..<numberOfPoints {
            let x = CGFloat(i) * (width / CGFloat(numberOfPoints - 1))
            let y = amplitude * (sin(CGFloat(i) * 0.2) + 0.5) // Create a wave shape
            let point = CGPoint(x: x, y: height - y)
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.addLine(to: CGPoint(x: width, y: height)) // Connect to bottom right
        path.addLine(to: CGPoint(x: 0, y: height)) // Connect to bottom left
        path.close()
        
        // Create shape layer
        waveAnimationLayer?.removeFromSuperlayer()
        waveAnimationLayer = CAShapeLayer()
        waveAnimationLayer?.path = path.cgPath
        waveAnimationLayer?.fillColor = UIColor.white.cgColor
    }
    
    private func startWaveAnimation() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.waveformView.transform = CGAffineTransform(scaleX: 1, y: 1.5)
        }, completion: nil)

    }
    
    private func stopWaveAnimation() {
        waveformView.layer.removeAllAnimations()
        waveformView.transform = .identity

    }
    
    // MARK: - Timer Handling
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.durationLabel.text = self.formatTime(player.currentTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        stopWaveAnimation()
        stopTimer()
        
        durationLabel.text = formatTime(player.duration)
        isPlaying = false
//        drawWaveform()
    }
    
    private func stopAudio() {
        guard let player = audioPlayer else { return }
        player.stop()
        player.currentTime = 0
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        stopWaveAnimation()
        stopTimer()
        
        durationLabel.text = formatTime(player.duration)
        isPlaying = false
//        drawWaveform()
    }
}
