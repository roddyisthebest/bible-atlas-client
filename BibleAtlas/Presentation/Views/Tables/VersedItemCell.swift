//
//  VersedItemCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/10/25.
//

import UIKit

final class VersedItemCell: UICollectionViewCell {
    
    static let identifier = "VersedItemCell"

    private var verseText: String? {
        didSet{
            label.text = verseText
        }
    }

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .primaryBlue
        label.textAlignment = .center
        contentView.addSubview(label)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle();
        setupConstraints();
        setupGesture();
    }

    private func setupStyle(){
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 4
    }
    
    private func setupConstraints(){
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(6)
        }
    }
    
    private func setupGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)
    }
    
    func configure(text: String) {
        verseText = text;
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleTap() {
        guard let text = verseText else { return }
        verseTappedHandler?(text)
    }

    var verseTappedHandler: ((String) -> Void)?
}

