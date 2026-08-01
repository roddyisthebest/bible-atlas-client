import UIKit
import SnapKit

final class ChatBotHeaderView: UIView {

    var onClose: (() -> Void)?
    var onInfoTapped: (() -> Void)?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .rounded(ofSize: 16, weight: .semibold)
        l.textAlignment = .center
        return l
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = .label
        return b
    }()

    private let infoButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        b.tintColor = .secondaryLabel
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        addSubviews()
        makeConstraints()
        wireActions()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func addSubviews() {
        addSubview(closeButton)
        addSubview(titleLabel)
        addSubview(infoButton)
    }

    private func makeConstraints() {
        closeButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(28)
        }
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        infoButton.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(4)
            $0.centerY.equalTo(titleLabel)
            $0.size.equalTo(24)
        }
    }

    private func wireActions() {
        closeButton.addAction(UIAction { [weak self] _ in self?.onClose?() }, for: .touchUpInside)
        infoButton.addAction(UIAction { [weak self] _ in self?.onInfoTapped?() }, for: .touchUpInside)
    }

    func setRemaining(_ remaining: Int) {
        titleLabel.text = "AI 챗봇 (\(remaining)/\(AgentUsecase.limit))"
    }
}
