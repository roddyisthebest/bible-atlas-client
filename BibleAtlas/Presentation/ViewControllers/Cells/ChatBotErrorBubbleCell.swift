import UIKit
import SnapKit

final class ChatBotErrorBubbleCell: UITableViewCell {
    static let reuseID = "ChatBotErrorBubbleCell"

    var onRetry: (() -> Void)?

    private let bubble: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.08)
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 0.5
        v.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.35).cgColor
        return v
    }()

    private let icon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let label: UILabel = {
        let l = UILabel()
        l.font = .rounded(ofSize: 13, weight: .regular)
        l.textColor = .label
        l.numberOfLines = 0
        return l
    }()

    private lazy var retryButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.image = UIImage(systemName: "arrow.clockwise")
        config.imagePlacement = .leading
        config.imagePadding = 4
        config.baseForegroundColor = .systemOrange
        config.cornerStyle = .capsule
        config.contentInsets = .init(top: 4, leading: 10, bottom: 4, trailing: 12)
        config.attributedTitle = AttributedString("재시도", attributes: AttributeContainer([
            .font: UIFont.rounded(ofSize: 12, weight: .semibold),
        ]))
        let b = UIButton(configuration: config)
        b.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)
        return b
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(bubble)
        bubble.addSubview(icon)
        bubble.addSubview(label)
        bubble.addSubview(retryButton)

        bubble.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().offset(-6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        icon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.size.equalTo(16)
        }
        label.snp.makeConstraints {
            $0.leading.equalTo(icon.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-12)
            $0.top.equalToSuperview().offset(10)
        }
        retryButton.snp.makeConstraints {
            $0.leading.equalTo(label)
            $0.top.equalTo(label.snp.bottom).offset(8)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onRetry = nil
    }

    func configure(text: String) {
        label.text = text
    }
}
