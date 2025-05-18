//
//  LoginBottomSheetViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/1/25.
//

import Foundation
import RxSwift
import RxRelay

protocol LoginBottomSheetViewModelProtocol {
    func transform(input:LoginBottomSheetViewModel.Input) -> LoginBottomSheetViewModel.Output
}

final class LoginBottomSheetViewModel:LoginBottomSheetViewModelProtocol {
    
    private let localId = "admin@naver.com"
    private let localPw = "one"
    
    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    private var authUsecase:AuthUsecaseProtocol?
    private var appStore:AppStoreProtocol?
    

    private let error$ = PublishRelay<NetworkError>()
    private let loading$ = BehaviorRelay<Bool>(value:false);
    
    init(navigator:BottomSheetNavigator?, usecase:AuthUsecaseProtocol?, appStore: AppStoreProtocol?){
        self.navigator = navigator
        self.authUsecase = usecase;
        self.appStore = appStore;
    }
    
    func transform(input: Input) -> Output {
        input.googleButtonTapped$.subscribe(onNext: {
            [weak self] in
            
        }).disposed(by: disposeBag)
        
        input.kakaoButtonTapped$.subscribe(onNext: {
            [weak self] in
            
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext: {
            [weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        input.localButtonTapped$.subscribe(onNext: {[weak self] in
            
            guard let self = self else { return }
            let localID = self.localId
            let localPW = self.localPw
            
            Task {
                self.loading$.accept(true)

                let result = await self.authUsecase?.loginUser(body: AuthPayload(userId: localID, password: localPW))
                    
                self.loading$.accept(false)

                switch(result){
                    case .success(let userResponse):
                        self.appStore?.dispatch(.login(userResponse.user))
                        self.navigator?.dismiss(animated: true)
                        print(userResponse)
                    case .failure(let networkError):
                        self.error$.accept(networkError)
                        print(networkError)
                    case .none:
                        print("none!")
                }
            }

            
        }).disposed(by: disposeBag)
        
        return Output(error$: error$.asObservable(), loading$: loading$.asObservable())
        
    }
    
    public struct Input {
        let localButtonTapped$:Observable<Void>
        let googleButtonTapped$:Observable<Void>
        let kakaoButtonTapped$:Observable<Void>
        let closeButtonTapped$:Observable<Void>
    }
    
    
    public struct Output {
        let error$:Observable<NetworkError>
        let loading$:Observable<Bool>
    }
}
