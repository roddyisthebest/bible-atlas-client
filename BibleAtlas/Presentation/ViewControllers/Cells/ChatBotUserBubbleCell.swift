import UIKit
import SnapKit

final class ChatBotUserBubbleCell: UITableViewCell {
    static let reuseID = "ChatBotUserBubbleCell"

    private let bubble: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 18
        return v
    }()

    private let label: UILabel = {
        let l = UILabel()
        l.font = .rounded(ofSize: 15, weight: .regular)
        l.textColor = .white
        l.numberOfLines = 0
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(bubble)
        bubble.addSubview(label)
        bubble.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().offset(-6)
            $0.trailing.equalToSuperview().offset(-16)
            $0.leading.greaterThanOrEqualToSuperview().offset(48)
        }
        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String) {
        label.text = text
    }
}
