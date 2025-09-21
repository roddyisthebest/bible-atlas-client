//
//  RelatedVerseTableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/10/25.
//

import UIKit
import SnapKit


protocol RelatedVerseTableViewCellDelegate: AnyObject {
    func didTapVerse(_ verse: String, in cell: RelatedVerseTableViewCell)
}

final class RelatedVerseTableViewCell: UITableViewCell {

    weak var delegate: RelatedVerseTableViewCellDelegate?
    
    private var collectionViewHeightConstraint: Constraint?


    private var verses: [String] = [];
    
    private var title: String = "" {
        didSet{
            titleLabel.text = title
        }
    }

    static let identifier = "relatedVerseCell"

    private lazy var containerStackView:UIStackView = {
        let sv = UIStackView(arrangedSubviews: [titleLabel, collectionView]);
        sv.axis = .vertical;
        sv.spacing = 10;
        sv.alignment = .fill
        sv.distribution = .fill;
        contentView.addSubview(sv)

        return sv;
    }()
    
    
    private let titleLabel = {
        let label = UILabel();
        label.text = "창세기"
        label.textColor = .detailLabelText;
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.font = .boldSystemFont(ofSize: 14)
        return label;
    }()
    
 
    private lazy var collectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.register(VersedItemCell.self, forCellWithReuseIdentifier: VersedItemCell.identifier)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        return cv
    }()
    
    private func setupStyle(){
        backgroundColor = .mainItemBkg;
    }
    
    private func setupConstraints(){
        containerStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20).priority(.low)
        }
        
        collectionView.snp.makeConstraints { make in
              self.collectionViewHeightConstraint = make.height.equalTo(1).priority(.low).constraint
        }
        
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints();
        setupStyle();
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupConstraints();
        setupStyle();
    }

    func configure(with verses: [String], title: String) {
        self.verses = verses
         self.title = title
         collectionView.reloadData()
         collectionView.collectionViewLayout.invalidateLayout()
         collectionView.layoutIfNeeded()

         let height = collectionView.collectionViewLayout.collectionViewContentSize.height
         collectionViewHeightConstraint?.update(offset: height)
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//
//        collectionView.collectionViewLayout.invalidateLayout()
//        collectionView.layoutIfNeeded()
//
//        let height = collectionView.collectionViewLayout.collectionViewContentSize.height
//        collectionViewHeightConstraint?.update(offset: height)
//    }

}


extension RelatedVerseTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return verses.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VersedItemCell.identifier, for: indexPath) as! VersedItemCell
        
        cell.configure(text: verses[indexPath.item])
        
        cell.verseTappedHandler = { [weak self] tappedVerse in
            guard let self = self else { return }
            let full = "\(title) \(tappedVerse)"

            self.delegate?.didTapVerse(full, in: self)
        }
        
        return cell
    }
}


#if DEBUG
extension RelatedVerseTableViewCell {
    func _test_fireTap(verse: String) {
        delegate?.didTapVerse(verse, in: self)
    }
}
#endif
