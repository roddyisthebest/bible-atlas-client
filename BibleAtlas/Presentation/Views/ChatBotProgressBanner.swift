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

    private let retryButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("재시도", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        b.isHidden = true
        return b
    }()

    var onRetry: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        addSubview(stack)
        stack.addArrangedSubview(spinner)
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(retryButton)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        }
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)
        isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func apply(_ progress: ChatBotBottomSheetViewModel.ChatProgress) {
        switch progress {
        case .idle:
            isHidden = true
            spinner.stopAnimating()
        case .running(let text):
            isHidden = false
            label.text = text
            spinner.isHidden = false
            spinner.startAnimating()
            retryButton.isHidden = true
        case .error(let message):
            isHidden = false
            label.text = message
            spinner.stopAnimating()
            spinner.isHidden = true
            retryButton.isHidden = false
        }
    }
}
