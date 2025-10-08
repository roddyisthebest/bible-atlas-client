//
//  MockPlaceDetailBottomSheetViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/21/25.
//


import Foundation
import RxSwift
import RxRelay
@testable import BibleAtlas

final class MockPlaceDetailViewModel: PlaceDetailViewModelProtocol {
    // MARK: - Outputs (테스트에서 주입/발행용)
    let place$          = BehaviorRelay<Place?>(value: nil)
    let bibles$         = BehaviorRelay<([Bible],Int)>(value: ([],0))
    let loadError$      = BehaviorRelay<NetworkError?>(value: nil)
    let interactionErr$ = BehaviorRelay<NetworkError?>(value: nil)
    let isLoading$      = BehaviorRelay<Bool>(value: false)
    let isSaving$       = BehaviorRelay<Bool>(value: false)
    let isLiking$       = BehaviorRelay<Bool>(value: false)
    let isLoggedIn$     = BehaviorRelay<Bool>(value: false)
    let profile$        = BehaviorRelay<User?>(value: nil)
    let hasPrev$        = BehaviorRelay<Bool>(value: false)

    // MARK: - Inputs 캡처
    private(set) var viewLoadedCount = 0
    private(set) var saveTapCount = 0
    private(set) var closeTapCount = 0
    private(set) var backTapCount = 0
    private(set) var likeTapCount = 0
    private(set) var placeModTapCount = 0
    private(set) var memoTapCount = 0
    private(set) var refetchTapCount = 0
    private(set) var tappedPlaceIds: [String] = []
    private(set) var tappedVerses: [String] = []
    private(set) var reportedTypes: [PlaceReportType] = []

    private let disposeBag = DisposeBag()

    // MARK: - PlaceDetailViewModelProtocol
    var currentPlace: Place? { place$.value }

    

    func transform(input: PlaceDetailViewModel.Input) -> PlaceDetailViewModel.Output {
        // Inputs record
        input.viewLoaded$
            .subscribe(onNext: { [weak self] in self?.viewLoadedCount += 1 })
            .disposed(by: disposeBag)

        input.saveButtonTapped$
            .subscribe(onNext: { [weak self] in self?.saveTapCount += 1 })
            .disposed(by: disposeBag)

        input.closeButtonTapped$
            .subscribe(onNext: { [weak self] in self?.closeTapCount += 1 })
            .disposed(by: disposeBag)

        input.backButtonTapped$
            .subscribe(onNext: { [weak self] in self?.backTapCount += 1 })
            .disposed(by: disposeBag)

        input.likeButtonTapped$
            .subscribe(onNext: { [weak self] in self?.likeTapCount += 1 })
            .disposed(by: disposeBag)

        input.placeModificationButtonTapped$
            .subscribe(onNext: { [weak self] in self?.placeModTapCount += 1 })
            .disposed(by: disposeBag)

        input.memoButtonTapped$
            .subscribe(onNext: { [weak self] in self?.memoTapCount += 1 })
            .disposed(by: disposeBag)

        input.placeCellTapped$
            .subscribe(onNext: { [weak self] pid in self?.tappedPlaceIds.append(pid) })
            .disposed(by: disposeBag)

        input.verseCellTapped$
            .subscribe(onNext: { [weak self] (bibleBook, verse) in self?.tappedVerses.append(verse) })
            .disposed(by: disposeBag)

        input.refetchButtonTapped$
            .subscribe(onNext: { [weak self] in self?.refetchTapCount += 1 })
            .disposed(by: disposeBag)

        input.reportButtonTapped$
            .subscribe(onNext: { [weak self] t in self?.reportedTypes.append(t) })
            .disposed(by: disposeBag)

        return PlaceDetailViewModel.Output(
            place$: place$.asObservable(),
            bibles$: bibles$.asObservable(),
            loadError$: loadError$.asObservable(),
            interactionError$: interactionErr$.asObservable(),
            isLoading$: isLoading$.asObservable(),
            isSaving$: isSaving$.asObservable(),
            isLiking$: isLiking$.asObservable(),
            isLoggedIn$: isLoggedIn$.asObservable(),
            profile$: profile$.asObservable(),
            hasPrevPlaceId$: hasPrev$.asObservable()
        )
    }

    // MARK: - 편의 주입 함수
    func emit(place: Place?)                   { place$.accept(place) }
    func emit(bibles: ([Bible], Int))                 { bibles$.accept(bibles) }
    func setLoading(_ v: Bool)                 { isLoading$.accept(v) }
    func setSaving(_ v: Bool)                  { isSaving$.accept(v) }
    func setLiking(_ v: Bool)                  { isLiking$.accept(v) }
    func setLoadError(_ e: NetworkError?)      { loadError$.accept(e) }
    func setInteractionError(_ e: NetworkError?) { interactionErr$.accept(e) }
    func setLoggedIn(_ v: Bool)                { isLoggedIn$.accept(v) }
    func setProfile(_ u: User?)                { profile$.accept(u) }
    func setHasPrev(_ v: Bool)                 { hasPrev$.accept(v) }
}
