//
//  HomeBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 4/28/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

enum HomeScreenMode: Equatable {
    case home
    case searchReady
    case searching
}

protocol HomeBottomSheetViewModelProtocol {
    func transform(input: HomeBottomSheetViewModel.Input) -> HomeBottomSheetViewModel.Output
    
    var screenMode$: Observable<HomeScreenMode> { get }
    var keyword$: Observable<String> { get }
}

final class HomeBottomSheetViewModel: HomeBottomSheetViewModelProtocol {

    private let disposeBag = DisposeBag()

    private weak var navigator: BottomSheetNavigator?
    private let authUsecase: AuthUsecaseProtocol?
    private var appStore: AppStoreProtocol?
    private var recentSearchService: RecentSearchServiceProtocol?
    private var notificationService: RxNotificationServiceProtocol?

    private let scheduler: SchedulerType

    
    // ✅ 읽기 전용 export
    var screenMode$: Observable<HomeScreenMode> { modeRelay.asObservable() }
    var keyword$: Observable<String> { keywordRelay.asObservable() }

    
    
    // ===== 내부 상태(단일 진실) =====
    private let modeRelay = BehaviorRelay<HomeScreenMode>(value: .home)
    private let keywordRelay = BehaviorRelay<String>(value: "")

    // ===== 외부로 나가는 상태 =====
    private let isLoggedInRelay = BehaviorRelay<Bool>(value: false)
    private let profileRelay = BehaviorRelay<User?>(value: nil)

    private let forceMediumRelay = PublishRelay<Void>()
    private let restoreDetentsRelay = PublishRelay<Void>()

    init(
        navigator: BottomSheetNavigator?,
        appStore: AppStoreProtocol?,
        authUseCase: AuthUsecaseProtocol?,
        recentSearchService: RecentSearchServiceProtocol?,
        notificationService: RxNotificationServiceProtocol?,
        schedular: SchedulerType = MainScheduler.instance
    ) {
        self.navigator = navigator
        self.appStore = appStore
        self.authUsecase = authUseCase
        self.recentSearchService = recentSearchService
        self.notificationService = notificationService
        self.scheduler = schedular

        bindAppStore()
        bindNotificationService()
    }

    func transform(input: Input) -> Output {

        // 1) 아바타 탭 -> 로그인 여부로 화면 전환
        input.avatarButtonTapped$
            .withLatestFrom(profileRelay.asObservable())
            .subscribe(onNext: { [weak self] profile in
                guard let self else { return }
                if profile != nil { self.navigator?.present(.myPage) }
                else { self.navigator?.present(.login) }
            })
            .disposed(by: disposeBag)

        // 2) 편집 시작 -> home이면 searchReady로 전환
        input.editingDidBegin$
            .withLatestFrom(modeRelay.asObservable())
            .filter { $0 == .home }
            .map { _ in HomeScreenMode.searchReady }
            .bind(to: modeRelay)
            .disposed(by: disposeBag)

        // 3) 키워드 변경 -> keywordRelay 업데이트 + 모드 결정
        input.keywordChanged$
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .distinctUntilChanged()
            .observe(on: scheduler)
            .subscribe(onNext: { [weak self] trimmed in
                guard let self else { return }
                self.keywordRelay.accept(trimmed)

                let nextMode: HomeScreenMode
                if trimmed.isEmpty {
                    // 검색 UI에 들어온 상태라면 searchReady 유지, 아니면 home
                    nextMode = (self.modeRelay.value == .home) ? .home : .searchReady
                } else {
                    nextMode = .searching
                }

                if self.modeRelay.value != nextMode {
                    self.modeRelay.accept(nextMode)
                }
            })
            .disposed(by: disposeBag)

        // 4) Cancel -> home + 키워드 초기화
        input.cancelButtonTapped$
            .observe(on: scheduler)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.keywordRelay.accept("")
                self.modeRelay.accept(.home)
            })
            .disposed(by: disposeBag)

        return Output(
            profile$: profileRelay.asObservable(),
            isLoggedIn$: isLoggedInRelay.asObservable(),
            screenMode$: modeRelay.distinctUntilChanged().asDriver(onErrorJustReturn: .home),
            keywordText$: keywordRelay.asDriver(onErrorJustReturn: ""),
            forceMedium$: forceMediumRelay.asObservable(),
            restoreDetents$: restoreDetentsRelay.asObservable()
        )
    }

    private func bindAppStore() {
        appStore?.state$
            .asObservable()
            .subscribe(onNext: { [weak self] state in
                self?.isLoggedInRelay.accept(state.isLoggedIn)
                self?.profileRelay.accept(state.profile)
            })
            .disposed(by: disposeBag)
    }

    private func bindNotificationService() {
        notificationService?.observe(.sheetCommand)
            .compactMap { $0.object as? SheetCommand }
            .subscribe(onNext: { [weak self] cmd in
                switch cmd {
                case .forceMedium:
                    self?.forceMediumRelay.accept(())
                case .restoreDetents:
                    self?.restoreDetentsRelay.accept(())
                }
            })
            .disposed(by: disposeBag)
    }

    // ===== Input / Output =====
    struct Input {
        let avatarButtonTapped$: Observable<Void>
        let cancelButtonTapped$: Observable<Void>
        let editingDidBegin$: Observable<Void>
        let keywordChanged$: Observable<String>
    }

    struct Output {
        let profile$: Observable<User?>
        let isLoggedIn$: Observable<Bool>

        // ✅ VC가 이것만 보면 UI 전부 결정 가능
        let screenMode$: Driver<HomeScreenMode>

        // ✅ textField 표시용 (루프 방지용으로 Driver)
        let keywordText$: Driver<String>

        // 기존 유지
        let forceMedium$: Observable<Void>
        let restoreDetents$: Observable<Void>
    }
}
