//
//  UIFont.swift
//  BibleAtlas
//
//  Created by 배성연 on 11/4/25.
//

import UIKit


private extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let desc = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: desc, size: pointSize)
    }
}



func makeMarkdownBold(_ text: String,
                      baseFont: UIFont = .systemFont(ofSize: 16),
                      textColor: UIColor = .label,
                      lineHeight: CGFloat = 22) -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.minimumLineHeight = lineHeight
    paragraph.maximumLineHeight = lineHeight

    let baseAttrs: [NSAttributedString.Key: Any] = [
        .font: baseFont,
        .foregroundColor: textColor,
        .paragraphStyle: paragraph
    ]

    let attributed = NSMutableAttributedString(string: text, attributes: baseAttrs)

    // **...** (백슬래시로 이스케이프한 \** 는 무시)
    let pattern = #"(?<!\\)\*\*(.+?)(?<!\\)\*\*"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return attributed
    }

    let matches = regex.matches(in: attributed.string,
                                options: [],
                                range: NSRange(location: 0, length: attributed.string.utf16.count))

    // 뒤에서부터 처리(인덱스 꼬임 방지)
    let boldFont = baseFont.withTraits(.traitBold)
    for m in matches.reversed() {
        // 캡처된 내부 텍스트 범위에 Bold 적용
        let inner = m.range(at: 1)
        attributed.addAttributes([.font: boldFont], range: inner)

        // 마커 ** ** 제거 (오른쪽 → 왼쪽 순서로)
        let full = m.range(at: 0)
        let rightMarker = NSRange(location: full.location + full.length - 2, length: 2)
        let leftMarker  = NSRange(location: full.location, length: 2)
        attributed.replaceCharacters(in: rightMarker, with: "")
        attributed.replaceCharacters(in: leftMarker, with: "")
    }

    // 이스케이프 문자 제거: \** → ** 로 보이게
    let escapePattern = #"\\\*\*"#
    if let escRegex = try? NSRegularExpression(pattern: escapePattern) {
        let full = NSRange(location: 0, length: attributed.string.utf16.count)
        escRegex.matches(in: attributed.string, options: [], range: full)
            .reversed()
            .forEach { attributed.replaceCharacters(in: $0.range, with: "**") }
    }

    return attributed
}



// MARK: - Highlight Helper
enum HighlightMode {
    case wholeWord
    case substring
}

// 부분 매치 지원 하이라이트 헬퍼
func makeHighlightedVerse(
    _ text: String,
    keyword rawKeyword: String,
    mode: HighlightMode = .substring,
    baseFont: UIFont = .systemFont(ofSize: 16),
    textColor: UIColor = .mainText,
    highlightFont: UIFont = .systemFont(ofSize: 16, weight: .semibold),
    highlightColor: UIColor = .primaryBlue
) -> NSAttributedString {
    let attr = NSMutableAttributedString(string: text, attributes: [
        .font: baseFont,
        .foregroundColor: textColor
    ])

    let keyword = rawKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !keyword.isEmpty else { return attr }

    let escaped = NSRegularExpression.escapedPattern(for: keyword)
    let isLatinSingleWord = keyword.range(of: #"^[A-Za-z]+$"#, options: .regularExpression) != nil

    // 부분 매치이면 그대로, wholeWord는 라틴 단어에만 경계 적용
    let pattern: String
    switch mode {
    case .wholeWord where isLatinSingleWord:
        pattern = #"(?<![A-Za-z])\#(escaped)(?![A-Za-z])"#
    default:
        pattern = escaped
    }

    if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        regex.enumerateMatches(in: text, options: [], range: range) { m, _, _ in
            guard let r = m?.range else { return }
            attr.addAttributes([
                .font: highlightFont,
                .foregroundColor: highlightColor
            ], range: r)
        }
    }
    return attr
}


