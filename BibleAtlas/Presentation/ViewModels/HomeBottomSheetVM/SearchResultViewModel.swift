//
//  SearchResultViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/21/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol SearchResultViewModelProtocol {
    func transform(input: SearchResultViewModel.Input) -> SearchResultViewModel.Output
}

final class SearchResultViewModel: SearchResultViewModelProtocol {

    private let disposeBag = DisposeBag()

    private weak var navigator: BottomSheetNavigator?
    private let placeUsecase: PlaceUsecaseProtocol?
    private var pagination = Pagination(pageSize: 20)

    private let places$ = BehaviorRelay<[Place]>(value: [])
    private let errorToFetchPlaces$ = BehaviorRelay<NetworkError?>(value: nil)
    private let errorToSaveRecentSearch$ = BehaviorRelay<RecentSearchError?>(value: nil)

    private let isSearching$ = BehaviorRelay<Bool>(value: false)
    private let isFetchingNext$ = BehaviorRelay<Bool>(value: false)

    // ✅ 의존성: screenMode + keyword만
    private let screenMode$: Observable<HomeScreenMode>
    private let keyword$: Observable<String>

    private let recentSearchService: RecentSearchServiceProtocol?
    private let schedular: SchedulerType

    init(
        navigator: BottomSheetNavigator? = nil,
        placeUsecase: PlaceUsecaseProtocol?,
        screenMode$: Observable<HomeScreenMode>,
        keyword$: Observable<String>,
        recentSearchService: RecentSearchServiceProtocol?,
        schedular: SchedulerType = MainScheduler.instance
    ) {
        self.navigator = navigator
        self.placeUsecase = placeUsecase
        self.screenMode$ = screenMode$
        self.keyword$ = keyword$
        self.recentSearchService = recentSearchService
        self.schedular = schedular
    }

    func transform(input: Input) -> Output {

        let debouncedKeyword$ = keyword$
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(.milliseconds(250), scheduler: schedular)
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)

        let distinctMode$ = screenMode$
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)

        // ✅ 모드/키워드에 따라 "한 곳에서" 상태 결정
        Observable
            .combineLatest(debouncedKeyword$, distinctMode$)
            .observe(on: schedular)
            .subscribe(onNext: { [weak self] keyword, mode in
                guard let self else { return }

                switch mode {
                case .home:
                    self.resetToIdle(clearResults: true)
                    return

                case .searchReady:
                    // 검색 화면 대기: 결과 비움(원하면 유지로 바꿔도 됨)
                    self.resetToIdle(clearResults: true)
                    return

                case .searching:
                    guard !keyword.isEmpty else {
                        self.resetToIdle(clearResults: true)
                        return
                    }
                    self.pagination.reset()
                    self.getPlaces(keyword: keyword)
                }
            })
            .disposed(by: disposeBag)

        // ✅ 페이징은 searching 모드 + (확정된) 키워드일 때만
        let debouncedBottomReached$ = input.bottomReached$
            .debounce(.milliseconds(200), scheduler: schedular)

        Observable
            .combineLatest(debouncedBottomReached$, distinctMode$, debouncedKeyword$)
            .observe(on: schedular)
            .subscribe(onNext: { [weak self] _, mode, keyword in
                guard let self else { return }
                guard mode == .searching else { return }
                guard !keyword.isEmpty else { return }
                self.getMorePlaces(keyword: keyword)
            })
            .disposed(by: disposeBag)

        // ✅ 셀 선택 -> 최근검색 저장 + 디테일 이동
        input.placeCellSelected$
            .observe(on: schedular)
            .subscribe(onNext: { [weak self] place in
                guard let self else { return }

                let result = self.recentSearchService?.save(place)
                switch result {
                case .success:
                    self.navigator?.present(.placeDetail(place.id))
                case .failure(let error):
                    self.errorToSaveRecentSearch$.accept(error)
                case .none:
                    break
                }
            })
            .disposed(by: disposeBag)

        // ✅ 재시도는 "현재 debouncedKeyword" 기준이 안전
        input.refetchButtonTapped$
            .withLatestFrom(debouncedKeyword$)
            .observe(on: schedular)
            .subscribe(onNext: { [weak self] keyword in
                guard let self else { return }
                guard !keyword.isEmpty else { return }
                self.pagination.reset()
                self.getPlaces(keyword: keyword)
            })
            .disposed(by: disposeBag)

        return Output(
            places$: places$.asObservable(),
            errorToFetchPlaces$: errorToFetchPlaces$.asObservable(),
            errorToSaveRecentSearch$: errorToSaveRecentSearch$.asObservable(),
            isSearching$: isSearching$.asObservable(),
            isFetchingNext$: isFetchingNext$.asObservable(),
            debouncedKeyword$: debouncedKeyword$.asObservable()
        )
    }

    private func resetToIdle(clearResults: Bool) {
        if clearResults {
            places$.accept([])
            errorToFetchPlaces$.accept(nil)
        }
        isSearching$.accept(false)
        isFetchingNext$.accept(false)
        pagination.reset()
    }

    private func getPlaces(keyword: String) {
        isSearching$.accept(true)

        Task { [weak self] in
            guard let self else { return }
            defer { self.isSearching$.accept(false) }

            let parameters = PlaceParameters(
                limit: self.pagination.pageSize,
                page: self.pagination.page,
                placeTypeName: nil,
                name: keyword,
                prefix: nil,
                sort: nil
            )

            let result = await self.placeUsecase?.getPlaces(parameters: parameters)

            switch result {
            case .success(let response):
                self.places$.accept(response.data)
                self.pagination.update(total: response.total)
                self.errorToFetchPlaces$.accept(nil)

            case .failure(let error):
                self.errorToFetchPlaces$.accept(error)

            case .none:
                break
            }
        }
    }

    private func getMorePlaces(keyword: String) {
        if isFetchingNext$.value || !pagination.hasMore { return }

        isFetchingNext$.accept(true)

        Task { [weak self] in
            guard let self else { return }
            defer { self.isFetchingNext$.accept(false) }

            guard self.pagination.advanceIfPossible() else { return }

            let parameters = PlaceParameters(
                limit: self.pagination.pageSize,
                page: self.pagination.page,
                placeTypeName: nil,
                name: keyword,
                prefix: nil,
                sort: nil
            )

            let result = await self.placeUsecase?.getPlaces(parameters: parameters)

            switch result {
            case .success(let response):
                let current = self.places$.value
                self.places$.accept(current + response.data)
                self.pagination.update(total: response.total)

            case .failure(let error):
                self.errorToFetchPlaces$.accept(error)

            case .none:
                break
            }
        }
    }

    struct Input {
        let refetchButtonTapped$: Observable<Void>
        let bottomReached$: Observable<Void>
        let placeCellSelected$: Observable<Place>
    }

    struct Output {
        let places$: Observable<[Place]>
        let errorToFetchPlaces$: Observable<NetworkError?>
        let errorToSaveRecentSearch$: Observable<RecentSearchError?>
        let isSearching$: Observable<Bool>
        let isFetchingNext$: Observable<Bool>
        let debouncedKeyword$: Observable<String>
    }
}
