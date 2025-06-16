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
        
    private weak var navigator:BottomSheetNavigator?
    
    private let isFirstFetching$ = BehaviorRelay<Bool>(value:false);
    
    private let selectedPlaceId$ = BehaviorRelay<String?>(value: nil);
    
    private let resetMapView$ = PublishRelay<Void>()
    
    
    private var placesWithRepresentativePoint$ = BehaviorRelay<[Place]>(value: []);
    
    
    private let mapUseCase:MapUsecaseProtocol?
    private let placeUsecase:PlaceUsecaseProtocol?
    
    private let notificationService: RxNotificationServiceProtocol?

    init(bottomSheetCoordinator:BottomSheetNavigator? ,mapUseCase: MapUsecaseProtocol?,placeUsecase: PlaceUsecaseProtocol? ,notificationService:RxNotificationServiceProtocol) {
        self.mapUseCase = mapUseCase
        self.placeUsecase = placeUsecase
        self.notificationService = notificationService
        self.navigator = bottomSheetCoordinator
        bindNotificationService();
    }
    
    func transform(input:Input) -> Output {
        
        input.viewLoaded$.subscribe(onNext: { [weak self] in
            self?.getPlacesWithRepresentativePoint();
        }).disposed(by: disposeBag)
        
        input.placeAnnotationTapped$.subscribe(onNext:{
            [weak self] placeId in
            
            let selectedPlaceId = self?.selectedPlaceId$.value;
            if(selectedPlaceId != placeId){
                self?.navigator?.present(.placeDetail(placeId, nil))
            }

        }).disposed(by: disposeBag)
        
        return Output(error$: error$.asObservable(), isLoading$: isLoading$.asObservable(), geoJsonRender$: geoJsonRender$.asObservable(), resetMapView$: resetMapView$.asObservable(), selectedPlaceId$: selectedPlaceId$.asObservable(), placesWithRepresentativePoint$: placesWithRepresentativePoint$.asObservable())
    }

    
    private func getPlacesWithRepresentativePoint(){
            
        isLoading$.accept(true)
        
        Task{
            defer{
                isLoading$.accept(false)
            }
            
            let result = await self.placeUsecase?.getPlacesWithRepresentativePoint();
                
            
            
            switch(result){
            case.success(let response):
                self.placesWithRepresentativePoint$.accept(response.data);
            case .failure(let error):
                print(error)
            case.none:
                print("none")
            }
        }
        
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
                self?.resetMapView$.accept(Void())
                self?.selectedPlaceId$.accept(nil)
                if let places = self?.placesWithRepresentativePoint$.value {
                    self?.placesWithRepresentativePoint$.accept(places)
                }
                
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
        let placeAnnotationTapped$:Observable<String>
    }
    
    public struct Output{
        let error$:Observable<NetworkError?>
        let isLoading$:Observable<Bool>
        let geoJsonRender$:Observable<[MKGeoJSONFeature]>
        let resetMapView$:Observable<Void>
        let selectedPlaceId$:Observable<String?>
        let placesWithRepresentativePoint$:Observable<[Place]>
    }
    
}
