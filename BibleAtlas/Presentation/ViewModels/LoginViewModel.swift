//
//  LoginViewModel.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/4/25.
//

import Foundation
import RxSwift
import RxRelay

protocol LoginViewModelProtocol{
    func transform(input:LoginViewModel.Input) -> LoginViewModel.Output
}


final class LoginViewModel: LoginViewModelProtocol{
    
    private let disposeBag = DisposeBag();
    
    private let loginResponse$ = PublishRelay<UserResponse>();
    private let error$ = PublishRelay<String>()
    
    private let authUsecase:AuthUsecaseProtocol;
    
    init(authUsecase: AuthUsecaseProtocol) {
        self.authUsecase = authUsecase
    }
    
    func transform(input: Input) -> Output {
        input.buttonTapped$.withLatestFrom(Observable.combineLatest(input.userId$, input.password$)).subscribe(onNext: {
            [weak self] (userId, password) in
            self?.loginUser(userId: userId, password: <#T##String#>)
            
        }).disposed(by: disposeBag)
        
        return Output(loginResponse$: loginResponse$.asObservable(), error$: error$.asObservable())
        
    }
    
    
    public struct Input{
        let userId$:Observable<String>
        let password$:Observable<String>
        let buttonTapped$:Observable<Void>
    }
    
    public struct Output{
        let loginResponse$:Observable<UserResponse>
        let error$:Observable<String>
    }
    
    
    private func loginUser(userId:String, password:String){
        Task{
            let result = await authUsecase.loginUser(body: AuthPayload(userId: userId, password: password));
            
            switch(result){
            case .success(let response):
                self.loginResponse$.accept(response);
                
            case .failure(let error):
                self.error$.accept(error.description)
                
            }
        }
    }
    
}
