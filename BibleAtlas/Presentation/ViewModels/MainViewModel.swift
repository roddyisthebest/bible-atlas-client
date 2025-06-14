//
//  MainViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/9/25.
//

import Foundation
import RxSwift
import RxRelay
import MapKit

protocol MainViewModelProtocol{
    func transform(input:MainViewModel.Input) -> MainViewModel.Output
}

final class MainViewModel: MainViewModelProtocol {
    private let disposeBag = DisposeBag();
    private let geoJsonRender$ = PublishRelay<[MKGeoJSONFeature]>()
    private let error$ = BehaviorRelay<NetworkError?>(value: nil)
    private let isLoading$ = BehaviorRelay<Bool>(value: false);
    private let selectedPlaceId$ = BehaviorRelay<String?>(value: nil);
    
    private let clearMapView$ = PublishRelay<Void>()

    
    
    private let mapUseCase:MapUsecaseProtocol?
    
    private let notificationService: RxNotificationServiceProtocol?

    init(mapUseCase: MapUsecaseProtocol?, notificationService:RxNotificationServiceProtocol) {
        self.mapUseCase = mapUseCase
        self.notificationService = notificationService
        
        bindNotificationService();
    }
    
    func transform(input:Input) -> Output {
        
        input.viewLoaded$.subscribe(onNext: { [weak self] in
            
            
        }).disposed(by: disposeBag)
        
        
        return Output(error$: error$.asObservable(), isLoading$: isLoading$.asObservable(), geoJsonRender$: geoJsonRender$.asObservable(), clearMapView$: clearMapView$.asObservable(), selectedPlaceId$: selectedPlaceId$.asObservable())
    }
    
    
    private func bindNotificationService(){
        self.notificationService?.observe(.fetchGeoJsonRequired)
            .observe(on: MainScheduler.instance)
            .compactMap { $0.object as? String }
            .subscribe(onNext: { [weak self] placeId in
                self?.selectedPlaceId$.accept(placeId)
                self?.fetchGeoJson(placeId: placeId)
            }).disposed(by: disposeBag)
        
        self.notificationService?.observe(.resetGeoJson)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.clearMapView$.accept(Void())
            })
            .disposed(by: disposeBag)
        
        
        
    }
    
    private func fetchGeoJson(placeId:String){
        isLoading$.accept(true)
        error$.accept(nil)
        
        
        Task{
            defer{
                isLoading$.accept(false)
            }
            
            let result = await mapUseCase?.getGeoJson(placeId: placeId);
            
            switch result {
            case .success(let response):
                geoJsonRender$.accept(response)
            case .failure(let error):
                error$.accept(error)
            case .none:
                print("none")
            }
        }
        
    }
    
    public struct Input {
        let viewLoaded$:Observable<Void>

    }
    
    public struct Output{
        let error$:Observable<NetworkError?>
        let isLoading$:Observable<Bool>
        let geoJsonRender$:Observable<[MKGeoJSONFeature]>
        let clearMapView$:Observable<Void>
        let selectedPlaceId$:Observable<String?>
    }
    
}
