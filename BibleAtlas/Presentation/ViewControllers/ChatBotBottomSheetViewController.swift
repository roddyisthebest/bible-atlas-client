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
    private let progressBanner = ChatBotProgressBanner()
    private let inputContainer = UIView()
    private let textField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.placeholder = "무엇이든 물어보세요"
        tf.returnKeyType = .send
        return tf
    }()
    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("보내기", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        return b
    }()

    private var bubbles: [ChatBubble] = []
    private let disposeBag = DisposeBag()

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
        bindViewModel()
        viewDidLoadRelay.accept(())
    }

    // MARK: - UI setup

    private func setupUI() {
        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(progressBanner)
        view.addSubview(inputContainer)
        inputContainer.addSubview(textField)
        inputContainer.addSubview(sendButton)

        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(52)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(progressBanner.snp.top).offset(-4)
        }
        progressBanner.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(inputContainer.snp.top).offset(-4)
            $0.height.greaterThanOrEqualTo(0)
        }
        inputContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
            $0.height.equalTo(56)
        }
        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.bottom.equalToSuperview().inset(8)
            $0.trailing.equalTo(sendButton.snp.leading).offset(-8)
        }
        sendButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(60)
        }

        headerView.onClose = { [weak self] in self?.dismiss(animated: true) }
        headerView.onInfoTapped = { [weak self] in self?.presentInfoAlert() }
        progressBanner.onRetry = { [weak self] in self?.retryRelay.accept(()) }

        sendButton.addAction(UIAction { [weak self] _ in self?.triggerSend() }, for: .touchUpInside)
        textField.addAction(UIAction { [weak self] _ in self?.triggerSend() }, for: .editingDidEndOnExit)
    }

    private func triggerSend() {
        let text = textField.text ?? ""
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        sendRelay.accept(text)
        textField.text = ""
    }

    private func presentInfoAlert() {
        let alert = UIAlertController(
            title: "안내",
            message: "아직 베타 버전이라 사용 횟수를 100회로 제한하고 있어요.\n사용해 주셔서 감사해요!",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func setupTable() {
        tableView.register(ChatBotUserBubbleCell.self, forCellReuseIdentifier: ChatBotUserBubbleCell.reuseID)
        tableView.register(ChatBotAssistantBubbleCell.self, forCellReuseIdentifier: ChatBotAssistantBubbleCell.reuseID)
        tableView.register(ChatBotErrorBubbleCell.self, forCellReuseIdentifier: ChatBotErrorBubbleCell.reuseID)
        tableView.dataSource = self
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
                self.scrollToBottom()
            })
            .disposed(by: disposeBag)

        output.progress
            .drive(onNext: { [weak self] p in self?.progressBanner.apply(p) })
            .disposed(by: disposeBag)

        output.remainingCount
            .drive(onNext: { [weak self] r in
                self?.headerView.setRemaining(r)
                if r == 0 { self?.textField.placeholder = "베타 사용 한도에 도달했어요" }
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
            })
            .disposed(by: disposeBag)

        output.routeToPlaceDetail
            .emit(onNext: { [weak self] placeId in
                self?.navigator?.present(.placeDetail(placeId))
            })
            .disposed(by: disposeBag)

        output.showLimitAlert
            .emit(onNext: { [weak self] in
                let alert = UIAlertController(
                    title: "안내",
                    message: "베타 사용 한도(100회)에 도달했어요.",
                    preferredStyle: .alert
                )
                alert.addAction(.init(title: "확인", style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func scrollToBottom() {
        guard !bubbles.isEmpty else { return }
        let last = IndexPath(row: bubbles.count - 1, section: 0)
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: last, at: .bottom, animated: true)
        }
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
            cell.onPlaceIdSelected = { [weak self] placeId in self?.placeSelectedRelay.accept(placeId) }
            cell.onChipTapped = { [weak self] text in self?.chipRelay.accept(text) }
            return cell
        case .error:
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatBotErrorBubbleCell.reuseID, for: indexPath) as! ChatBotErrorBubbleCell
            cell.configure(text: bubble.text)
            return cell
        }
    }
}
