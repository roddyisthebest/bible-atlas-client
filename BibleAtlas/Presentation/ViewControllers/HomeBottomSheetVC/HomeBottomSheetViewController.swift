//
//  HomeBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

//
//  HomeBottomSheetViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/19/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Kingfisher

final class HomeBottomSheetViewController: UIViewController {

    private let homeBottomSheetViewModel: HomeBottomSheetViewModelProtocol

    private let homeContentViewController: HomeContentViewController
    private let searchReadyViewController: SearchReadyViewController
    private let searchResultViewController: SearchResultViewController

    private var myDetents: [UISheetPresentationController.Detent] = []
    private let disposeBag = DisposeBag()

    // ✅ child VC를 넣는 전용 컨테이너 (attach-once 방식 대비)
    private let contentContainerView = UIView()
    private weak var currentChild: UIViewController?

    private lazy var bodyView: UIView = {
        let v = UIView()
        v.addSubview(headerStackView)
        v.addSubview(contentContainerView)
        return v
    }()

    private lazy var headerStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [searchTextField, userAvatarButton, cancelButton])
        sv.axis = .horizontal
        sv.spacing = 10
        sv.distribution = .fill
        sv.alignment = .fill
        return sv
    }()

    private lazy var searchTextField: UISearchTextField = {
        let input = UISearchTextField()
        input.delegate = self
        input.placeholder = L10n.Home.searchPlaceholder
        input.font = .systemFont(ofSize: 16)
        input.returnKeyType = .done
        input.autocorrectionType = .no
        input.spellCheckingType = .no
        input.translatesAutoresizingMaskIntoConstraints = false
        return input
    }()

    private lazy var userAvatarButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .userAvatarBkg
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.setTitle(L10n.Home.login, for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.addSubview(userAvatarImageView)
        return button
    }()

    private let userAvatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.Home.cancel, for: .normal)
        button.setTitleColor(.primaryBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.isHidden = true
        return button
    }()

    private let lowDetent = UISheetPresentationController.Detent.custom { _ in
        UIScreen.main.bounds.height * 0.2
    }

    // MARK: - Init
    init(
        homeBottomSheetViewModel: HomeBottomSheetViewModelProtocol,
        homeContentViewController: HomeContentViewController,
        searchReadyViewController: SearchReadyViewController,
        searchResultViewController: SearchResultViewController
    ) {
        self.homeBottomSheetViewModel = homeBottomSheetViewModel
        self.homeContentViewController = homeContentViewController
        self.searchReadyViewController = searchReadyViewController
        self.searchResultViewController = searchResultViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStyle()
        setupConstraints()
        attachChildVCsIfNeeded()         // ✅ 여기서 3개 child를 한 번에 붙임
        bindViewModel()
        setupDismissTextFieldOnTap()
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(bodyView)
        self.myDetents = self.sheetPresentationController?.detents ?? []
    }

    private func setupStyle() {
        view.backgroundColor = .mainBkg
    }

    private func setupConstraints() {
        bodyView.snp.makeConstraints { $0.edges.equalToSuperview() }

        headerStackView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
        }

        userAvatarButton.snp.makeConstraints { $0.width.equalTo(40) }
        userAvatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupDismissTextFieldOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissTextField))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissTextField() {
        searchTextField.resignFirstResponder()
    }

    // MARK: - Child VC pre-attach + show/hide (no fade)
    private var didAttachChildren = false

    private func attachChildVCsIfNeeded() {
        guard !didAttachChildren else { return }
        didAttachChildren = true

        let childrenToAttach: [UIViewController] = [
            homeContentViewController,
            searchReadyViewController,
            searchResultViewController
        ]

        childrenToAttach.forEach { vc in
            addChild(vc)
            view.insertSubview(vc.view, belowSubview: headerStackView)
            vc.view.snp.makeConstraints { make in
                make.top.equalTo(headerStackView.snp.bottom)
                make.leading.trailing.bottom.equalToSuperview()
            }
            vc.didMove(toParent: self)

            vc.view.isHidden = true
            vc.view.isUserInteractionEnabled = false
        }

        // initial
        showChild(homeContentViewController)
    }

    /// ✅ 가장 가벼운 전환: isHidden + userInteraction만 바꿈
    private func showChild(_ target: UIViewController) {
        // already visible -> no-op
        if !target.view.isHidden { return }

        let all = [homeContentViewController, searchReadyViewController, searchResultViewController]
        for vc in all {
            let isTarget = (vc === target)
            vc.view.isHidden = !isTarget
            vc.view.isUserInteractionEnabled = isTarget
        }
    }


    // MARK: - Bind
    private func bindViewModel() {
        let input = HomeBottomSheetViewModel.Input(
            avatarButtonTapped$: userAvatarButton.rx.tap.asObservable(),
            cancelButtonTapped$: cancelButton.rx.tap.asObservable(),
            editingDidBegin$: searchTextField.rx.controlEvent(.editingDidBegin).asObservable(),
            keywordChanged$: searchTextField.rx.text.orEmpty.asObservable()
        )

        let output = homeBottomSheetViewModel.transform(input: input)

        // 1) TextField 표시용
        output.keywordText$
            .distinctUntilChanged()
            .drive(searchTextField.rx.text)
            .disposed(by: disposeBag)

        // 2) screenMode 하나로 UI 전부 반영
        output.screenMode$
            .distinctUntilChanged()
            .drive(onNext: { [weak self] mode in
                let id = spBegin("screenMode_onNext")
                defer { spEnd("screenMode_onNext", id) }
                self?.apply(mode: mode)
            })
            .disposed(by: disposeBag)

        // 3) 로그인/프로필 UI
        Observable
            .combineLatest(output.isLoggedIn$, output.profile$)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoggedIn, profile in
                guard let self else { return }

                if isLoggedIn, let profile {
                    self.userAvatarImageView.isHidden = false
                    self.setAvatarImage(urlString: profile.avatar)
                    self.userAvatarButton.setTitle("", for: .normal)
                } else {
                    self.userAvatarButton.setTitle(L10n.Home.login, for: .normal)
                    self.userAvatarImageView.isHidden = true
                }
            })
            .disposed(by: disposeBag)

        // 4) sheetCommand 유지
        output.forceMedium$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.sheetPresentationController?.animateChanges {
                    self.myDetents = self.sheetPresentationController?.detents ?? []
                    self.sheetPresentationController?.detents = [.medium()]
                    self.sheetPresentationController?.largestUndimmedDetentIdentifier = .medium
                    self.sheetPresentationController?.selectedDetentIdentifier = .medium
                }
            })
            .disposed(by: disposeBag)

        output.restoreDetents$
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.sheetPresentationController?.animateChanges {
                    self.sheetPresentationController?.detents = self.myDetents
                    self.sheetPresentationController?.selectedDetentIdentifier = (self.myDetents.count > 1) ? .medium : .large
                }
            })
            .disposed(by: disposeBag)
    }

    // ✅ 모드별 UI는 여기만 본다
    private func apply(mode: HomeScreenMode) {
        switch mode {
        case .searchReady:
            lockToLargeDetentCoalesced()
            showChild(searchReadyViewController)
            userAvatarButton.isHidden = true
            cancelButton.isHidden = false

        case .searching:
            lockToLargeDetentCoalesced()
            showChild(searchResultViewController)
            userAvatarButton.isHidden = true
            cancelButton.isHidden = false

        case .home:
            showChild(homeContentViewController)
            userAvatarButton.isHidden = false
            cancelButton.isHidden = true
            restoreDetentsAndDismissKeyboard()
        }
    }
    
    private var pendingLockToLarge = false

    private func lockToLargeDetentCoalesced() {
        guard !pendingLockToLarge else { return }
        pendingLockToLarge = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.pendingLockToLarge = false

            guard let sheet = self.sheetPresentationController else { return }

            // 이미 large + locked면 스킵
            if sheet.detents.count == 1, sheet.selectedDetentIdentifier == .large { return }

            sheet.animateChanges {
                sheet.detents = [.large()]
                sheet.selectedDetentIdentifier = .large
            }
        }
    }

    private func restoreDetentsAndDismissKeyboard() {
        let id = spBegin("restoreDetentsAndDismissKeyboard")
        defer { spEnd("restoreDetentsAndDismissKeyboard", id) }

        guard let sheet = sheetPresentationController else { return }

        searchTextField.resignFirstResponder()
        sheet.detents = [.large(), .medium(), lowDetent]
        myDetents = [.large(), .medium(), lowDetent]
        sheet.animateChanges {
            sheet.selectedDetentIdentifier = .medium
        }
    }

    private func setAvatarImage(urlString: String) {
        let replaced = urlString.replacingOccurrences(of: "svg", with: "png")
        guard let url = URL(string: replaced) else { return }
        userAvatarImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
    }
}

extension HomeBottomSheetViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { true }
}

#if DEBUG
extension HomeBottomSheetViewController {
    // ====== 읽기 전용 상태 ======

    /// 현재 child VC의 클래스명 (예: "HomeContentViewController", "SearchReadyViewController", "SearchResultViewController")
    var _test_currentChildClassName: String? {
        return children.first.map { String(describing: type(of: $0)) }
    }

    /// 아바타 버튼/캔슬 버튼 가시성
    var _test_isUserAvatarHidden: Bool { userAvatarButton.isHidden }
    var _test_isCancelHidden: Bool { cancelButton.isHidden }

    /// 검색 필드 텍스트
    var _test_searchText: String? {
        get { searchTextField.text }
        set { searchTextField.text = newValue }
    }

    /// 현재 시트 detent 선택값 (nil이면 시트가 없거나 선택값 없음)
    var _test_selectedDetentIdentifier: UISheetPresentationController.Detent.Identifier? {
        sheetPresentationController?.selectedDetentIdentifier
    }

    /// 현재 시트 detents 개수 (nil이면 시트 없음)
    var _test_detentsCount: Int? {
        sheetPresentationController?.detents.count
    }

    // ====== 사용자 상호작용 시뮬레이터 ======

    /// Cancel 버튼 탭 시뮬레이션
    func _test_tapCancel() {
        cancelButton.sendActions(for: .touchUpInside)
    }

    /// 아바타 버튼 탭 시뮬레이션
    func _test_tapAvatar() {
        userAvatarButton.sendActions(for: .touchUpInside)
    }

    /// 검색 필드 '편집 시작' 시그널 시뮬레이션
    /// - Rx `controlEvent(.editingDidBegin)`이 확실히 타도록 이벤트를 직접 발생시킨다.
    func _test_beginEditing() {
        // 먼저 first responder 설정 (UIKit 이벤트 흐름 유사)
        _ = searchTextField.becomeFirstResponder()

        // controlEvent(.editingDidBegin) 트리거
        searchTextField.sendActions(for: .editingDidBegin)
    }

    /// 검색 필드 '편집 종료' 시그널 시뮬레이션
    func _test_endEditing() {
        _ = searchTextField.resignFirstResponder()
        searchTextField.sendActions(for: .editingDidEnd)
    }

    /// 검색 텍스트 입력 시뮬레이션 (Rx 바인딩 타게 editingChanged 함께 보냄)
    func _test_typeSearchText(_ text: String) {
        searchTextField.text = text
        searchTextField.sendActions(for: .editingChanged)
    }
}
#endif
