import UIKit
import SnapKit

final class ChatBotProgressBanner: UIView {

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        return s
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = false
        return s
    }()

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        addSubview(stack)
        stack.addArrangedSubview(spinner)
        stack.addArrangedSubview(label)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        }
        isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    /// 진행 배너는 로딩만 담당. 에러는 채팅 로그의 에러 버블이 처리.
    func apply(_ progress: ChatBotBottomSheetViewModel.ChatProgress) {
        switch progress {
        case .idle, .error:
            isHidden = true
            spinner.stopAnimating()
        case .running(let text):
            isHidden = false
            label.text = text
            spinner.isHidden = false
            spinner.startAnimating()
        }
    }
}
