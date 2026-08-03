import UIKit
import SnapKit

/// 챗봇이 응답 준비 중일 때 채팅 맨 아래에 뜨는 "생각 중…" 버블.
final class ChatBotPendingBubbleCell: UITableViewCell {
    static let reuseID = "ChatBotPendingBubbleCell"

    private let bubble: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 18
        return v
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = false
        s.startAnimating()
        return s
    }()

    private let label: UILabel = {
        let l = UILabel()
        l.font = .rounded(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

    private lazy var stack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [spinner, label])
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(bubble)
        bubble.addSubview(stack)

        bubble.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().offset(-6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().offset(-48)
        }
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        spinner.startAnimating()
    }

    func configure(label text: String) {
        label.text = text
    }
}
