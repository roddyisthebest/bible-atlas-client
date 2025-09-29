import UIKit
import SnapKit

class RecentSearchTableViewCell: UITableViewCell {
    static let identifier = "searchCell"

    private let iconWrapper: UIView = {
        let v = UIView()
        v.backgroundColor = .searchCircle
        v.layer.cornerRadius = 15
        v.layer.masksToBounds = true
        return v
    }()

    private let searchIcon: UIImageView = {
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        return icon
    }()

    private let searchLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .mainText
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let containerStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.alignment = .center
        sv.distribution = .fill
        
        return sv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupStyle();
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupStyle();
    }

    private func setupUI() {
        contentView.addSubview(containerStackView)

        iconWrapper.addSubview(searchIcon)
        containerStackView.addArrangedSubview(iconWrapper)
        containerStackView.addArrangedSubview(searchLabel)
    }
    
    private func setupStyle(){
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        iconWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(30)
        }

        searchIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }
        backgroundColor = .mainItemBkg;
    }

//    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
//        super.setHighlighted(highlighted, animated: animated)
//
//        UIView.animate(withDuration: 0.2) {
//            self.containerStackView.backgroundColor = highlighted ? .focusedMainItemBkg : .mainItemBkg
//
//        }
//    }

    func setText(text: String, koreanText:String) {
        searchLabel.text = L10n.isEnglish ? text : koreanText
    }
}
