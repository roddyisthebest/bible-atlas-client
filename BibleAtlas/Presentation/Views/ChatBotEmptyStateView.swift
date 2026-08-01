import UIKit
import SnapKit

/// 챗봇 시트에서 아직 대화가 없을 때 보여주는 인사 + 이용 팁 카드.
final class ChatBotEmptyStateView: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(
            systemName: "bubble.left.and.text.bubble.right.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .regular)
        ))
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let greetingLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.ChatBot.greeting
        l.font = .rounded(ofSize: 18, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = L10n.ChatBot.greetingSubtitle
        l.font = .rounded(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private lazy var tipsCard: UIView = {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12

        let title = UILabel()
        title.text = L10n.ChatBot.tipsTitle
        title.font = .rounded(ofSize: 13, weight: .semibold)
        title.textColor = .label

        let tip1 = makeTipLabel(L10n.ChatBot.tip1)
        let tip2 = makeTipLabel(L10n.ChatBot.tip2)
        let tip3 = makeTipLabel(L10n.ChatBot.tip3)
        let tip4 = makeTipLabel(L10n.ChatBot.tip4)

        let stack = UIStackView(arrangedSubviews: [title, tip1, tip2, tip3, tip4])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .leading

        card.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        }
        return card
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        addSubview(iconView)
        addSubview(greetingLabel)
        addSubview(subtitleLabel)
        addSubview(tipsCard)

        iconView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.size.equalTo(48)
        }
        greetingLabel.snp.makeConstraints {
            $0.top.equalTo(iconView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(greetingLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }
        tipsCard.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makeTipLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .rounded(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }
}
