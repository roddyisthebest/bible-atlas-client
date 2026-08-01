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
        l.text = "무엇이 궁금하신가요?"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "성경 속 지역과 여정에 대해 물어보세요.\n아래 입력창에 질문을 입력하면 시작돼요."
        l.font = .systemFont(ofSize: 13)
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
        title.text = "✅ 이용 팁"
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = .label

        let tip1 = makeTipLabel("• 질문은 한 번에 하나씩 나눠서 해주세요.")
        let tip2 = makeTipLabel("• 성경 속 지역/장소·여정 질문에 가장 강해요.")
        let tip3 = makeTipLabel("• 지역명을 정확히 몰라도 키워드만 있으면 지역 설명과 현재 추정 위치까지 알려드려요.")
        let tip4 = makeTipLabel("• 성경 내용에 관한 일반 질문도 답변 가능하지만, 지역·여정 질문에서 가장 잘 작동해요.")

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
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }
}
