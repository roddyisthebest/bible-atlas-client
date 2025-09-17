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
    private weak var notificationService: RxNotificationServiceProtocol?

    private var appStore:AppStoreProtocol?
    

    private let error$ = PublishRelay<NetworkError>()
    private let localLoading$ = BehaviorRelay<Bool>(value:false);
    private let googleLoading$ = BehaviorRelay<Bool>(value:false);
    private let appleLoading$ = BehaviorRelay<Bool>(value:false);

    init(navigator:BottomSheetNavigator?, usecase:AuthUsecaseProtocol?, appStore: AppStoreProtocol?, notificationService:RxNotificationServiceProtocol?){
        self.navigator = navigator
        self.authUsecase = usecase;
        self.appStore = appStore;
        self.notificationService = notificationService
    }
    
    func transform(input: Input) -> Output {
        input.googleTokenReceived$.subscribe(onNext: {
            [weak self] idToken in
            guard let self = self, let idToken = idToken else { return }
            
            Task{
                self.googleLoading$.accept(true)
                
                defer{
                    self.googleLoading$.accept(false)
                }
                
                let result = await self.authUsecase?.loginGoogleUser(idToken: idToken);
                
                switch(result){
                    case .success(let response):
                        print(response)
                        self.notificationService?.post(.refetchRequired, object: nil)
                        self.appStore?.dispatch(.login(response.user))
                        self.navigator?.dismiss(animated: true)

                    case .failure(let networkError):
                        self.error$.accept(networkError)
                        print(networkError)
                    case .none:
                        print("none")
                }
                
            }
            
        }).disposed(by: disposeBag)
        
        
        input.appleTokenReceived$.subscribe(onNext: {
            [weak self] token in
            guard let self = self, let idToken = token else { return }
            Task{
                self.appleLoading$.accept(true)
                
                defer{
                    self.appleLoading$.accept(false)
                }
                
                let result = await self.authUsecase?.loginAppleUser(idToken: idToken);
                
                switch(result){
                    case .success(let response):

                        self.notificationService?.post(.refetchRequired, object: nil)
                        self.appStore?.dispatch(.login(response.user))
                        self.navigator?.dismiss(animated: true)
                    
                    case .failure(let networkError):
                        self.error$.accept(networkError)
                        print(networkError)
                    case .none:
                        print("none")
                }
                
            }
            
        }).disposed(by: disposeBag)
        
        input.localButtonTapped$.subscribe(onNext: {[weak self] in
            
            guard let self = self else { return }
            let localID = self.localId
            let localPW = self.localPw
            
            Task {
                self.localLoading$.accept(true)

                defer{
                    self.localLoading$.accept(false)
                }
                let result = await self.authUsecase?.loginUser(body: AuthPayload(userId: localID, password: localPW))
                    

                switch(result){
                    case .success(let userResponse):
                        print(userResponse)
                        self.notificationService?.post(.refetchRequired, object: nil)
                        self.appStore?.dispatch(.login(userResponse.user))
                        self.navigator?.dismiss(animated: true)

                    case .failure(let networkError):
                        self.error$.accept(networkError)
                        print(networkError)
                    case .none:
                        print("none!")
                }
            }
            
        
            
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext:{[weak self] in
            self?.navigator?.dismiss(animated: true)
        }).disposed(by: disposeBag)
        
        
        return Output(error$: error$.asObservable(), localLoading$: localLoading$.asObservable(), googleLoading$: googleLoading$.asObservable(), appleLoading$: appleLoading$.asObservable())
        
    }
    
    public struct Input {
        let localButtonTapped$:Observable<Void>
        let googleTokenReceived$:Observable<String?>
        let appleTokenReceived$:Observable<String?>
        let closeButtonTapped$:Observable<Void>
    }
    
    
    public struct Output {
        let error$:Observable<NetworkError>
        let localLoading$:Observable<Bool>
        let googleLoading$:Observable<Bool>
        let appleLoading$:Observable<Bool>
    }
}
