import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa

final class ChatBotBottomSheetViewController: UIViewController {

    private let viewModel: ChatBotBottomSheetViewModelProtocol
    private weak var navigator: BottomSheetNavigator?

    // Input relays
    private let viewDidLoadRelay = PublishRelay<Void>()
    private let sendRelay = PublishRelay<String>()
    private let chipRelay = PublishRelay<String>()
    private let placeSelectedRelay = PublishRelay<String>()
    private let retryRelay = PublishRelay<Void>()

    // UI
    private let headerView = ChatBotHeaderView()
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.keyboardDismissMode = .interactive
        tv.allowsSelection = false
        tv.estimatedRowHeight = 60
        tv.rowHeight = UITableView.automaticDimension
        return tv
    }()
    private let emptyStateView = ChatBotEmptyStateView()
    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 22
        v.layer.borderWidth = 0.5
        v.layer.borderColor = UIColor.separator.cgColor
        return v
    }()
    private let textField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.placeholder = L10n.ChatBot.placeholder
        tf.returnKeyType = .send
        tf.font = .rounded(ofSize: 15, weight: .regular)
        tf.textColor = .label
        tf.tintColor = .systemBlue
        return tf
    }()
    private let sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        let b = UIButton(configuration: config)
        b.accessibilityLabel = L10n.ChatBot.send
        return b
    }()

    private var bubbles: [ChatBubble] = []
    private let disposeBag = DisposeBag()
    /// 다른 시트가 detail 을 열 때 원래 detents 로 복구하기 위해 저장.
    private var myDetents: [UISheetPresentationController.Detent] = []

    // MARK: - Init

    init(viewModel: ChatBotBottomSheetViewModelProtocol, navigator: BottomSheetNavigator) {
        self.viewModel = viewModel
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupTable()
        setupKeyboardDismiss()
        bindViewModel()
        subscribeSheetCommand()
        viewDidLoadRelay.accept(())
    }

    private func setupKeyboardDismiss() {
        // 채팅 로그 아무데나 탭하면 키보드 내려가게. 셀 안의 버튼/링크는 정상 동작.
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 다른 VC 들과 동일하게, 초기 detents 를 기억해두고 나중에 복구용.
        if myDetents.isEmpty {
            myDetents = sheetPresentationController?.detents ?? []
        }
    }

    private func subscribeSheetCommand() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSheetCommand(_:)),
            name: .sheetCommand,
            object: nil
        )
    }

    @objc private func handleSheetCommand(_ note: Notification) {
        guard let command = note.object as? SheetCommand else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let presentation = self.sheetPresentationController else { return }
            presentation.animateChanges {
                switch command {
                case .forceMedium:
                    presentation.detents = [.medium()]
                    presentation.largestUndimmedDetentIdentifier = .medium
                    presentation.selectedDetentIdentifier = .medium
                case .restoreDetents:
                    presentation.detents = self.myDetents
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI setup

    private func setupUI() {
        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(textField)
        inputContainer.addSubview(sendButton)

        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(15)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(52)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(inputContainer.snp.top).offset(-4)
        }
        emptyStateView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalToSuperview().offset(-24)
            $0.centerY.equalTo(tableView)
        }
        inputContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top).offset(-8)
            $0.height.equalTo(44)
        }
        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(18)
            $0.top.bottom.equalToSuperview()
            $0.trailing.equalTo(sendButton.snp.leading).offset(-6)
        }
        sendButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-6)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }

        headerView.onClose = { [weak self] in self?.dismiss(animated: true) }
        headerView.onInfoTapped = { [weak self] in self?.presentInfoAlert() }

        sendButton.addAction(UIAction { [weak self] _ in self?.triggerSend() }, for: .touchUpInside)
        textField.addAction(UIAction { [weak self] _ in self?.triggerSend() }, for: .editingDidEndOnExit)
        textField.addAction(UIAction { [weak self] _ in self?.updateSendButtonAppearance() }, for: .editingChanged)
        // 텍스트필드 포커스 시 채팅 마지막 메시지가 보이도록 자동 스크롤.
        textField.addAction(UIAction { [weak self] _ in self?.scrollToBottom() }, for: .editingDidBegin)
        updateSendButtonAppearance()
    }

    private func updateSendButtonAppearance() {
        let hasText = !(textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        sendButton.alpha = hasText ? 1.0 : 0.35
    }

    private func triggerSend() {
        let text = textField.text ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let alert = UIAlertController(title: nil, message: L10n.ChatBot.emptyMessageAlert, preferredStyle: .alert)
            alert.addAction(.init(title: L10n.ChatBot.ok, style: .default))
            present(alert, animated: true)
            return
        }
        sendRelay.accept(text)
        textField.text = ""
        updateSendButtonAppearance()
    }

    private func presentInfoAlert() {
        let alert = UIAlertController(title: L10n.ChatBot.infoAlertTitle, message: L10n.ChatBot.infoAlertMessage, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.ChatBot.ok, style: .default))
        present(alert, animated: true)
    }

    private func setupTable() {
        tableView.register(ChatBotUserBubbleCell.self, forCellReuseIdentifier: ChatBotUserBubbleCell.reuseID)
        tableView.register(ChatBotAssistantBubbleCell.self, forCellReuseIdentifier: ChatBotAssistantBubbleCell.reuseID)
        tableView.register(ChatBotPendingBubbleCell.self, forCellReuseIdentifier: ChatBotPendingBubbleCell.reuseID)
        tableView.register(ChatBotErrorBubbleCell.self, forCellReuseIdentifier: ChatBotErrorBubbleCell.reuseID)
        tableView.dataSource = self
        // 마지막 메시지가 입력창에 붙지 않도록 하단 여유분. 스크롤해서 조금 더 내릴 수도 있음.
        tableView.contentInset.bottom = 40
        tableView.verticalScrollIndicatorInsets.bottom = 40
    }

    // MARK: - Binding

    private func bindViewModel() {
        let input = ChatBotBottomSheetViewModel.Input(
            viewDidLoad: viewDidLoadRelay,
            sendTapped: sendRelay,
            chipTapped: chipRelay,
            placeSelected: placeSelectedRelay,
            retryTapped: retryRelay
        )
        let output = viewModel.transform(input: input)

        output.bubbles
            .drive(onNext: { [weak self] bubbles in
                guard let self = self else { return }
                self.bubbles = bubbles
                self.tableView.reloadData()
                self.emptyStateView.isHidden = !bubbles.isEmpty
                self.scrollToBottom()
            })
            .disposed(by: disposeBag)

        // progress 는 pending 버블로 대체. 여기서는 별도 UI 갱신 없음.
        output.progress
            .drive()
            .disposed(by: disposeBag)

        output.remainingCount
            .drive(onNext: { [weak self] r in
                self?.headerView.setRemaining(r)
                if r == 0 { self?.textField.placeholder = L10n.ChatBot.placeholderReachedLimit }
            })
            .disposed(by: disposeBag)

        output.inputEnabled
            .drive(onNext: { [weak self] enabled in
                self?.textField.isEnabled = enabled
                self?.sendButton.isEnabled = enabled
            })
            .disposed(by: disposeBag)

        output.fillInputText
            .emit(onNext: { [weak self] text in
                self?.textField.text = text
                self?.textField.becomeFirstResponder()
                self?.updateSendButtonAppearance()
            })
            .disposed(by: disposeBag)

        output.routeToPlaceDetail
            .emit(onNext: { [weak self] placeId in
                // Coordinator 가 자동으로 .forceMedium 을 post 해서 챗봇 시트가 medium 으로 접힘.
                // dismiss 하지 않음 — 뒤로가기 시 원래 detent 로 복구되어 대화 유지.
                self?.navigator?.present(.placeDetail(placeId))
            })
            .disposed(by: disposeBag)

        output.showLimitAlert
            .emit(onNext: { [weak self] in
                let alert = UIAlertController(
                    title: L10n.ChatBot.limitAlertTitle,
                    message: L10n.ChatBot.limitAlertMessage(AgentUsecase.limit),
                    preferredStyle: .alert
                )
                alert.addAction(.init(title: L10n.ChatBot.ok, style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }

    /// 장소 링크 탭 처리. ids 1개면 바로 이동, 여러 개면 action sheet 로 선택.
    /// 옵션 라벨: 순차 번호 + id 접두사에 따른 시대 태그 (a=고대, m=현대 추정)
    private func handlePlaceSelection(name: String, ids: [String]) {
        if ids.count == 1 {
            placeSelectedRelay.accept(ids[0])
            return
        }
        let alert = UIAlertController(title: name, message: L10n.ChatBot.pickerMessage, preferredStyle: .actionSheet)
        for (index, id) in ids.enumerated() {
            let title = "\(name)\(index + 1) \(Self.eraTag(forPlaceId: id))"
            alert.addAction(.init(title: title, style: .default) { [weak self] _ in
                self?.placeSelectedRelay.accept(id)
            })
        }
        alert.addAction(.init(title: L10n.ChatBot.cancel, style: .cancel))
        // iPad 대응 (source view)
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    private static func eraTag(forPlaceId id: String) -> String {
        switch id.first?.lowercased() {
        case "a": return L10n.ChatBot.eraAncient
        case "m": return L10n.ChatBot.eraModern
        default:  return ""
        }
    }

    private func scrollToBottom() {
        guard !bubbles.isEmpty else { return }
        let last = IndexPath(row: bubbles.count - 1, section: 0)
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: last, at: .bottom, animated: true)
        }
    }
}

extension ChatBotBottomSheetViewController: UIGestureRecognizerDelegate {
    /// 셀 안의 버튼(칩·재시도)이나 UITextView 링크 탭은 gesture 로 가로채면 안 됨.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        var view: UIView? = touch.view
        while let v = view {
            if v is UIControl || v is UITextView { return false }
            view = v.superview
        }
        return true
    }
}

extension ChatBotBottomSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bubbles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bubble = bubbles[indexPath.row]
        switch bubble.kind {
        case .user:
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatBotUserBubbleCell.reuseID, for: indexPath) as! ChatBotUserBubbleCell
            cell.configure(text: bubble.text)
            return cell
        case .assistant(let placeIdMap, let questions):
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatBotAssistantBubbleCell.reuseID, for: indexPath) as! ChatBotAssistantBubbleCell
            cell.configure(text: bubble.text, placeIdMap: placeIdMap, recommendedQuestions: questions)
            cell.onPlaceSelected = { [weak self] name, ids in
                self?.handlePlaceSelection(name: name, ids: ids)
            }
            cell.onChipTapped = { [weak self] text in self?.chipRelay.accept(text) }
            return cell
        case .pending(let label):
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatBotPendingBubbleCell.reuseID, for: indexPath) as! ChatBotPendingBubbleCell
            cell.configure(label: label)
            return cell
        case .error:
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatBotErrorBubbleCell.reuseID, for: indexPath) as! ChatBotErrorBubbleCell
            cell.configure(text: bubble.text)
            cell.onRetry = { [weak self] in self?.retryRelay.accept(()) }
            return cell
        }
    }
}
