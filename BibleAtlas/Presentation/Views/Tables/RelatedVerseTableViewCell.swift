//
//  RelatedVerseTableViewCell.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/10/25.
//

import UIKit
import SnapKit


protocol RelatedVerseTableViewCellDelegate: AnyObject {
    func didTapVerse(bibleBook:BibleBook, keyword: String, in cell: RelatedVerseTableViewCell)
    func didTapMoreButton(bibleBook:BibleBook?, in cell: RelatedVerseTableViewCell)
}

enum Verse {
    case def(String)
    case more(Int)
}



final class RelatedVerseTableViewCell: UITableViewCell {

    weak var delegate: RelatedVerseTableViewCellDelegate?
    
    private var collectionViewHeightConstraint: Constraint?


    private var verses: [Verse] = [];
    
    private var bibleBook: BibleBook = .Etc {
        didSet{
            titleLabel.text = bibleBook.title()
        }
    }
    
    private var contentSizeObs: NSKeyValueObservation?

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
            make.height.equalTo(1).priority(.high)
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
    private let maxVerseCount = 15;
    
    func configure(with verses: [String], bibleBook: BibleBook) {
        let restVerseCount = max(verses.count - maxVerseCount, 0)
        self.verses = Array(verses.prefix(maxVerseCount)).map{.def($0)}
        
        if(restVerseCount>0){
            self.verses.append(.more(restVerseCount))
        }
        
        self.bibleBook = bibleBook
   
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
            
        let height = collectionView.collectionViewLayout.collectionViewContentSize.height
        
        collectionView.snp.updateConstraints { make in
            make.height.equalTo(height).priority(.high)
        }

    }


}


extension RelatedVerseTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return verses.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VersedItemCell.identifier, for: indexPath) as! VersedItemCell
        
        cell.configure(verse: verses[indexPath.item])
        
        cell.verseTappedHandler = { [weak self] tappedVerse in
            guard let self = self else { return }

            switch(tappedVerse){
                case .def(let keyword):
                    delegate?.didTapVerse(bibleBook: bibleBook, keyword: keyword, in: self)
                case .more:
                    delegate?.didTapMoreButton(bibleBook: bibleBook, in: self)
            }
        }
        
        return cell
    }
}


#if DEBUG
extension RelatedVerseTableViewCell {
    func _test_fireTap(verse: String) {
        delegate?.didTapVerse(bibleBook: bibleBook, keyword: verse, in: self)
    }
}
#endif
