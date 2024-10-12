//
//  MyCell.swift
//  Simple Chat
//
//  Created by M. Syulhan Al Ghofany on 03/10/24.
//

import UIKit
import SnapKit

class MyCell: UITableViewCell {
    
    var buttonTapCallback: () -> () = { }
    
    let button: UIButton = {
        let btn = UIButton()
        btn.setTitle("Button", for: .normal)
        btn.backgroundColor = .systemPink
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return btn
    }()
    
    let label: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = .systemPink
        return lbl
    }()
    
    @objc func didTapButton() {
        print("aaaaaaa")
        buttonTapCallback()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Add button
        contentView.addSubview(button)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        
        // Add label
        contentView.addSubview(label)
        
        // Set constraints using SnapKit
        button.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(10)
            make.width.equalTo(100)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        label.snp.makeConstraints { make in
            make.leading.equalTo(button.snp.trailing).offset(20)
            make.top.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
