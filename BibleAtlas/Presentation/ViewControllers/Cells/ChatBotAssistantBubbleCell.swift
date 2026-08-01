import UIKit
import SnapKit

final class ChatBotAssistantBubbleCell: UITableViewCell {
    static let reuseID = "ChatBotAssistantBubbleCell"

    /// (displayName, ids) — ids 개수에 따라 VC 가 바로 라우트하거나 선택 alert 를 띄운다.
    var onPlaceSelected: ((_ name: String, _ ids: [String]) -> Void)?
    var onChipTapped: ((String) -> Void)?

    /// 서버가 준 map 그대로. 서버 쪽에서 이미 병합/정규화됨.
    private var placeIdMap: [String: [String]] = [:]

    private let bubble: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 18
        return v
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.font = .rounded(ofSize: 15, weight: .regular)
        tv.textColor = .label
        tv.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.rounded(ofSize: 15, weight: .semibold),
        ]
        return tv
    }()

    private let chipsHeader: UILabel = {
        let l = UILabel()
        l.text = "💡 이런 질문은 어떠세요?"
        l.font = .rounded(ofSize: 12, weight: .semibold)
        l.textColor = .secondaryLabel
        l.isHidden = true
        return l
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
        bubble.addSubview(contentStack)

        contentStack.addArrangedSubview(textView)
        contentStack.addArrangedSubview(chipsHeader)
        contentStack.addArrangedSubview(chipsStack)
        // 텍스트와 추천 질문 헤더 사이만 좀 더 여백. 헤더/칩 사이는 기본 spacing (6).
        contentStack.setCustomSpacing(12, after: textView)

        bubble.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().offset(-6)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().offset(-48)
        }
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        }

        textView.delegate = self
    }

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 6
        return s
    }()

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chipsStack.isHidden = true
        chipsHeader.isHidden = true
        onPlaceSelected = nil
        onChipTapped = nil
        placeIdMap = [:]
    }

    func configure(text: String,
                   placeIdMap: [String: [String]],
                   recommendedQuestions: [String]) {
        self.placeIdMap = placeIdMap
        textView.attributedText = Self.makeAttributedString(text: text, placeNames: Array(placeIdMap.keys))

        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chipsHeader.isHidden = recommendedQuestions.isEmpty
        chipsStack.isHidden = recommendedQuestions.isEmpty
        for q in recommendedQuestions {
            let btn = Self.makeChipButton(title: q)
            btn.addAction(UIAction { [weak self] _ in self?.onChipTapped?(q) }, for: .touchUpInside)
            chipsStack.addArrangedSubview(btn)
        }
    }

    // MARK: - Helpers

    private static func makeAttributedString(text: String, placeNames: [String]) -> NSAttributedString {
        // 1. **볼드** 파싱: 텍스트에서 ** 를 벗기고 볼드 적용할 range 를 얻는다.
        let (stripped, boldRanges) = parseBold(text)

        // 2. 기본 스타일
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        let m = NSMutableAttributedString(string: stripped, attributes: [
            .font: UIFont.rounded(ofSize: 15, weight: .regular),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph,
        ])

        // 3. 볼드 range 에 bold weight 적용
        let boldFont = UIFont.rounded(ofSize: 15, weight: .bold)
        for range in boldRanges {
            m.addAttribute(.font, value: boldFont, range: range)
        }

        // 4. 장소명 링크 (place name lookup 은 볼드 벗긴 뒤 텍스트 기준)
        let ns = stripped as NSString
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

    /// `**text**` 패턴을 찾아 `**` 를 벗긴 최종 문자열과 각 볼드 부분의 NSRange 를 반환.
    /// 비-greedy 매칭 (`.+?`). 매칭 실패 시 원본 그대로 반환.
    private static func parseBold(_ text: String) -> (stripped: String, ranges: [NSRange]) {
        guard let regex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: [.dotMatchesLineSeparators]) else {
            return (text, [])
        }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        if matches.isEmpty { return (text, []) }

        let output = NSMutableString()
        var boldRanges: [NSRange] = []
        var cursor = 0

        for match in matches {
            let fullRange = match.range
            let innerRange = match.range(at: 1)
            if fullRange.location > cursor {
                output.append(ns.substring(with: NSRange(location: cursor, length: fullRange.location - cursor)))
            }
            let boldStart = output.length
            let content = ns.substring(with: innerRange)
            output.append(content)
            boldRanges.append(NSRange(location: boldStart, length: (content as NSString).length))
            cursor = fullRange.location + fullRange.length
        }
        if cursor < ns.length {
            output.append(ns.substring(with: NSRange(location: cursor, length: ns.length - cursor)))
        }
        return (output as String, boldRanges)
    }

    private static func makeChipButton(title: String) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.baseForegroundColor = .systemBlue
        config.background.strokeColor = .systemBlue.withAlphaComponent(0.25)
        config.background.strokeWidth = 1
        config.cornerStyle = .capsule
        config.contentInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.rounded(ofSize: 13, weight: .medium),
        ]))
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
              let ids = placeIdMap[name], !ids.isEmpty else {
            return false
        }
        onPlaceSelected?(name, ids)
        return false
    }
}
