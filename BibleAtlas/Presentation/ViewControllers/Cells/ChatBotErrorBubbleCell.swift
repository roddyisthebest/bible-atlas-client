import UIKit
import SnapKit

final class ChatBotErrorBubbleCell: UITableViewCell {
    static let reuseID = "ChatBotErrorBubbleCell"

    private let icon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(icon)
        contentView.addSubview(label)
        icon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(10)
            $0.size.equalTo(16)
        }
        label.snp.makeConstraints {
            $0.leading.equalTo(icon.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(8)
            $0.bottom.equalToSuperview().offset(-8)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String) {
        label.text = text
    }
}
