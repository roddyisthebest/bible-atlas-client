import UIKit
import SnapKit

final class ChatBotAssistantBubbleCell: UITableViewCell {
    static let reuseID = "ChatBotAssistantBubbleCell"

    var onPlaceIdSelected: ((String) -> Void)?
    var onChipTapped: ((String) -> Void)?

    private var placeIdMap: [String: [String]] = [:]

    private let bubble: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 16
        return v
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.font = .systemFont(ofSize: 15)
        tv.textColor = .label
        tv.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        return tv
    }()

    private let chipsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .leading
        s.spacing = 6
        s.isHidden = true
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(bubble)
        bubble.addSubview(textView)
        bubble.addSubview(chipsStack)

        bubble.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().offset(-6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().offset(-64)
        }
        textView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-12)
        }
        chipsStack.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(textView)
            $0.bottom.equalToSuperview().offset(-12)
        }

        textView.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chipsStack.isHidden = true
        onPlaceIdSelected = nil
        onChipTapped = nil
        placeIdMap = [:]
    }

    func configure(text: String,
                   placeIdMap: [String: [String]],
                   recommendedQuestions: [String]) {
        self.placeIdMap = placeIdMap
        textView.attributedText = Self.makeAttributedString(text: text, placeNames: Array(placeIdMap.keys))

        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chipsStack.isHidden = recommendedQuestions.isEmpty
        for q in recommendedQuestions {
            let btn = Self.makeChipButton(title: q)
            btn.addAction(UIAction { [weak self] _ in self?.onChipTapped?(q) }, for: .touchUpInside)
            chipsStack.addArrangedSubview(btn)
        }
    }

    // MARK: - Helpers

    private static func makeAttributedString(text: String, placeNames: [String]) -> NSAttributedString {
        let m = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label,
        ])
        let ns = text as NSString
        for name in placeNames where !name.isEmpty {
            var searchRange = NSRange(location: 0, length: ns.length)
            while true {
                let found = ns.range(of: name, options: [], range: searchRange)
                if found.location == NSNotFound { break }
                let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? name
                if let url = URL(string: "bibleatlas-place://\(encoded)") {
                    m.addAttribute(.link, value: url, range: found)
                }
                let next = found.location + found.length
                if next >= ns.length { break }
                searchRange = NSRange(location: next, length: ns.length - next)
            }
        }
        return m
    }

    private static func makeChipButton(title: String) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.baseForegroundColor = .systemBlue
        config.background.strokeColor = .systemBlue.withAlphaComponent(0.3)
        config.background.strokeWidth = 1
        config.cornerStyle = .capsule
        config.contentInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 12)
        let b = UIButton(configuration: config)
        b.titleLabel?.numberOfLines = 0
        return b
    }
}

extension ChatBotAssistantBubbleCell: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard URL.scheme == "bibleatlas-place",
              let name = URL.host?.removingPercentEncoding,
              let firstId = placeIdMap[name]?.first else {
            return false
        }
        onPlaceIdSelected?(firstId)
        return false
    }
}
