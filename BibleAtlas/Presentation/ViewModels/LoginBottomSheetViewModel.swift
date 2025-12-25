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

    private let disposeBag = DisposeBag();
    private weak var navigator: BottomSheetNavigator?
    private var authUsecase:AuthUsecaseProtocol?
    private weak var notificationService: RxNotificationServiceProtocol?

    private var appStore:AppStoreProtocol?
    

    private let error$ = PublishRelay<NetworkError>()
    private let googleLoading$ = BehaviorRelay<Bool>(value:false);
    private let appleLoading$ = BehaviorRelay<Bool>(value:false);
    private let localLoading$ = BehaviorRelay<Bool>(value:false);


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
                        await MainActor.run {
                            self.navigator?.dismiss(animated: true)
                        }

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
                        await MainActor.run {
                            self.navigator?.dismiss(animated: true)
                        }
                    
                    case .failure(let networkError):
                        self.error$.accept(networkError)
                        print(networkError)
                    case .none:
                        print("none")
                }
                
            }
            
        }).disposed(by: disposeBag)
        
        
        input.localLoginButtonTapped$.subscribe(onNext: {
            [weak self] (userId, password) in
            
            guard let self = self, let authUsecase = self.authUsecase else{
                
                self?.error$.accept(.clientError(L10n.FatalError.reExec))
                return;
            }
            
            guard
                let userId = userId?.trimmingCharacters(in: .whitespacesAndNewlines),
                let password = password?.trimmingCharacters(in: .whitespacesAndNewlines),
                !userId.isEmpty,
                !password.isEmpty
            else {
                self.error$.accept(.clientError(L10n.Login.invalidFormat))
                return
            }
            
            Task{
                self.localLoading$.accept(true)
                
                defer{
                    self.localLoading$.accept(false)
                }
                
                let result = await authUsecase.loginUser(body: AuthPayload(userId: userId, password: password))
                
                switch(result){
                    case .success(let response):
                        self.notificationService?.post(.refetchRequired, object: nil)
                        self.appStore?.dispatch(.login(response.user))
                        await MainActor.run {
                            self.navigator?.dismiss(animated: true)
                        }
                    case .failure(let networkError):
                        self.error$.accept(networkError)

                }
            }
        }).disposed(by: disposeBag)
        
        input.closeButtonTapped$.subscribe(onNext:{[weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.navigator?.dismiss(animated: true)
            }
        }).disposed(by: disposeBag)
        
        
        return Output(error$: error$.asObservable(), googleLoading$: googleLoading$.asObservable(), appleLoading$: appleLoading$.asObservable(), localLoading$: localLoading$.asObservable())
        
    }
    
    public struct Input {
        let googleTokenReceived$:Observable<String?>
        let appleTokenReceived$:Observable<String?>
        let localLoginButtonTapped$:Observable<(String?, String?)>
        let closeButtonTapped$:Observable<Void>
    }
    
    
    public struct Output {
        let error$:Observable<NetworkError>
        let googleLoading$:Observable<Bool>
        let appleLoading$:Observable<Bool>
        let localLoading$:Observable<Bool>
    }
}
