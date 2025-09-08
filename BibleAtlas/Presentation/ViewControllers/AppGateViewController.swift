import UIKit
import SnapKit

/// App gate: 서버 OK일 때만 메인 진입
@MainActor
final class AppGateViewController: UIViewController {
    // MARK: - Dependencies
    private let healthChecker: HealthCheckServiceProtocol
    private let onPassed: () -> Void
    private var isPassing = false

    // MARK: - UI
    private let gradientLayer = CAGradientLayer()
    private let card = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let content = UIStackView()

    private let logoView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "LaunchLogoPurple"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.hidesWhenStopped = true
        return v
    }()

    private let messageLabel: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.font = .systemFont(ofSize: 15, weight: .medium)
        lb.textColor = .secondaryLabel
        return lb
    }()

    private let retryButton: UIButton = {
        let bt = UIButton(type: .system)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = "Retry"
            config.baseBackgroundColor = .systemIndigo
            config.baseForegroundColor = .white
            config.cornerStyle = .large
            config.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
            bt.configuration = config
        } else {
            bt.setTitle("Retry", for: .normal)
            bt.setTitleColor(.white, for: .normal)
            bt.backgroundColor = .systemIndigo
            bt.layer.cornerRadius = 12
            bt.contentEdgeInsets = .init(top: 10, left: 16, bottom: 10, right: 16)
        }
        bt.isHidden = true
        return bt
    }()

    // MARK: - Init
    init(healthChecker: HealthCheckServiceProtocol, onPassed: @escaping () -> Void) {
        self.healthChecker = healthChecker
        self.onPassed = onPassed
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupLayout()   // ① card를 view에 먼저 붙임
        setupCard()     // ② card 내부 구성 및 제약 (card 기준)
        retryButton.addTarget(self, action: #selector(onRetry), for: .touchUpInside)
        animateIn()
        runGate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        card.layer.cornerRadius = 24
        card.clipsToBounds = true
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.15
        card.layer.shadowRadius = 18
        card.layer.shadowOffset = CGSize(width: 0, height: 10)
    }

    // MARK: - Setup (background & card)
    private func setupBackground() {
        // 브랜드 그라데로 바꾸고 싶으면 아래 두 줄을 원하는 색으로 바꿔도 됨.
        let top = UIColor(named: "LaunchBackground") ?? UIColor.systemBackground
        let bottom = top == .systemBackground ? UIColor.secondarySystemBackground : top.withAlphaComponent(0.92)

        gradientLayer.colors = [
            top.resolvedColor(with: traitCollection).cgColor,
            bottom.resolvedColor(with: traitCollection).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupLayout() {
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-20)
            make.width.lessThanOrEqualTo(420)
        }
    }

    private func setupCard() {
        // Stack 설정
        content.axis = .vertical
        content.alignment = .center
        content.distribution = .fill
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = .init(top: 24, left: 24, bottom: 24, right: 24)

        // Stack을 card에 추가
        card.contentView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 요소 추가
        content.addArrangedSubview(logoView)
        content.addArrangedSubview(spinner)
        content.addArrangedSubview(messageLabel)
        content.addArrangedSubview(retryButton)

        // ⛔ 루트 view 기준 금지
        // ✅ card 기준으로 로고 크기 제한 (공통 조상 보장)
        logoView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(card.snp.width).multipliedBy(0.6)
            make.height.equalTo(logoView.snp.width) // 1:1
        }

        spinner.snp.makeConstraints { make in
            make.height.equalTo(32)
        }

        // 큰 화면에서 과도하게 넓어지지 않도록 메시지 최대폭 제한
        messageLabel.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(360)
        }
    }

    // MARK: - Actions
    @objc private func onRetry() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        runGate()
    }

    private func setLoading(_ loading: Bool, text: String? = nil) {
        if loading {
            spinner.startAnimating()
            retryButton.isHidden = true
            messageLabel.text = text ?? "Checking server status…"
            messageLabel.textColor = .secondaryLabel
        } else {
            spinner.stopAnimating()
        }
    }

    // MARK: - Gate Flow
    private func runGate() {
        guard !isPassing else { return }
        setLoading(true)

        Task {
            do {
                let status = try await healthChecker.check()
                switch status {
                case .ok:
                    isPassing = true
                    setLoading(true, text: "Restoring session…")
                    onPassed() // Coordinator/Main 전환
                case .maintenance(let msg):
                    setLoading(false)
                    showInfo(msg.isEmpty ? "Under maintenance." : msg)
                case .blocked(let msg):
                    setLoading(false)
                    showError(msg.isEmpty ? "Access is restricted." : msg)
                }
            } catch {
                setLoading(false)
                let nsErr = error as NSError
                let msg: String
                if nsErr.domain == NSURLErrorDomain, nsErr.code == URLError.timedOut.rawValue {
                    msg = "Request timed out. Please check your connection and try again."
                } else {
                    msg = "Network error: \(error.localizedDescription)"
                }
                showError(msg)
            }
        }
    }

    // MARK: - UI helpers
    private func animateIn() {
        card.alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        logoView.alpha = 0
        logoView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)

        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut]) {
            self.card.alpha = 1
            self.card.transform = .identity
        }

        UIView.animate(withDuration: 0.6,
                       delay: 0.05,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.6,
                       options: []) {
            self.logoView.alpha = 1
            self.logoView.transform = .identity
        }
    }

    private func showError(_ text: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        messageLabel.text = text
        messageLabel.textColor = .label
        retryButton.isHidden = false
        shake(card)
    }

    private func showInfo(_ text: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        messageLabel.text = text
        messageLabel.textColor = .label
        retryButton.isHidden = false
    }

    private func shake(_ view: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        anim.duration = 0.4
        anim.values = [0, -10, 8, -6, 4, -2, 0]
        view.layer.add(anim, forKey: "shake")
    }
}
