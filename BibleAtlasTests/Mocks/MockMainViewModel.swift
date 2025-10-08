//
//  MockMainViewModel.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 9/19/25.
//

import Foundation
import RxSwift
import RxRelay
import MapKit

@testable import BibleAtlas

final class MockMainViewModel: MainViewModelProtocol {

    // MARK: - Input capture (spy)
    private(set) var transformCallCount = 0
    private(set) var viewLoadedCount = 0
    private(set) var tappedPlaceIds: [String] = []
    var onViewLoaded: (() -> Void)?
    var onPlaceTap: ((String) -> Void)?

    private let disposeBag = DisposeBag()

    // MARK: - Output relays (control from tests)
    let errorRelay = BehaviorRelay<NetworkError?>(value: nil)
    let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let geoJsonRenderRelay = PublishRelay<[MKGeoJSONFeature]>()
    let resetMapViewRelay = PublishRelay<Void>()
    let zoomOutMapViewRelay = PublishRelay<Void>()
    let selectedPlaceIdRelay = BehaviorRelay<String?>(value: nil)
    let placesWithRepresentativePointRelay = BehaviorRelay<[Place]>(value: [])

    // MARK: - Helpers for tests (emit outputs)
    func emitError(_ e: NetworkError?) { errorRelay.accept(e) }
    func setLoading(_ v: Bool) { isLoadingRelay.accept(v) }
    func emitGeoJSON(_ features: [MKGeoJSONFeature]) { geoJsonRenderRelay.accept(features) }
    func emitReset() { resetMapViewRelay.accept(()) }
    func emitZoomOut() { zoomOutMapViewRelay.accept(()) }
    func setSelectedPlaceId(_ id: String?) { selectedPlaceIdRelay.accept(id) }
    func setPlaces(_ places: [Place]) { placesWithRepresentativePointRelay.accept(places) }

    // MARK: - Protocol
    func transform(input: MainViewModel.Input) -> MainViewModel.Output {
        transformCallCount += 1

        input.viewLoaded$
            .subscribe(onNext: { [weak self] in
                self?.viewLoadedCount += 1
                self?.onViewLoaded?()
            })
            .disposed(by: disposeBag)

        input.placeAnnotationTapped$
            .subscribe(onNext: { [weak self] id in
                self?.tappedPlaceIds.append(id)
                self?.onPlaceTap?(id)
            })
            .disposed(by: disposeBag)

        return MainViewModel.Output(
            error$: errorRelay.asObservable(),
            isLoading$: isLoadingRelay.asObservable(),
            geoJsonRender$: geoJsonRenderRelay.asObservable(),
            resetMapView$: resetMapViewRelay.asObservable(),
            selectedPlaceId$: selectedPlaceIdRelay.asObservable(),
            placesWithRepresentativePoint$: placesWithRepresentativePointRelay.asObservable()
        )
    }

    // MARK: - Reset between tests
    func reset() {
        transformCallCount = 0
        viewLoadedCount = 0
        tappedPlaceIds.removeAll()
        errorRelay.accept(nil)
        isLoadingRelay.accept(false)
        selectedPlaceIdRelay.accept(nil)
        placesWithRepresentativePointRelay.accept([])
        // PublishRelay들은 상태가 없어 별도 초기화 필요 없음
    }
}

