//
//  TextChatCell.swift
//  Simple Chat
//
//  Created by M. Syulhan Al Ghofany on 04/10/24.
//

import UIKit
import SnapKit
import FirebaseFirestore

class TextChatCell: UITableViewCell {

    let messageLabel = UILabel()
    let timeLabel = UILabel()
    let bubbleBackgroundView = UIView()
    
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
        bubbleBackgroundView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
    }
    
    private func setupUI() {
        bubbleBackgroundView.backgroundColor = UIColor.systemBlue
        bubbleBackgroundView.layer.cornerRadius = 15
        
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = .lightGray
        
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .white
        
        timeLabel.font = UIFont.systemFont(ofSize: 10)
        timeLabel.textColor = .lightGray
    }
    
    private func setupConstraint() {
        bubbleBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10).priority(.high)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(bubbleBackgroundView.snp.leading).offset(-5)
            make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
        }
        
        messageLabel.setContentHuggingPriority(.required, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    func configure(with message: String, timestamp: Timestamp, isSender: Bool = true) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeString = dateFormatter.string(from: timestamp.dateValue())
        
        messageLabel.text = message
        timeLabel.text = timeString
        
        if isSender {
            bubbleBackgroundView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            
            bubbleBackgroundView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.trailing.equalToSuperview().offset(-20)
                make.leading.greaterThanOrEqualToSuperview().offset(50)
                make.bottom.equalToSuperview().offset(-10).priority(.high)
            }
            
            timeLabel.snp.remakeConstraints { make in
                make.trailing.equalTo(bubbleBackgroundView.snp.leading).offset(-5)
                make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
            }
            
        } else {
            bubbleBackgroundView.backgroundColor = .lightGray
            messageLabel.textColor = .black
            
            bubbleBackgroundView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.leading.equalToSuperview().offset(20)
                make.trailing.lessThanOrEqualToSuperview().offset(-50)
                make.bottom.equalToSuperview().offset(-10).priority(.high)
            }
            
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleBackgroundView.snp.trailing).offset(5)
                make.bottom.equalTo(bubbleBackgroundView.snp.bottom)
            }
        }
    }
}
