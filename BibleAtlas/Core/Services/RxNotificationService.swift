//
//  RxNotificationService.swift
//  BibleAtlas
//
//  Created by 배성연 on 6/5/25.
//

import Foundation
import RxSwift
import RxCocoa


protocol RxNotificationServiceProtocol:AnyObject {
    func post(_ name: Notification.Name, object: Any?)
    func observe(_ name: Notification.Name) -> Observable<Notification>
}


final class RxNotificationService: RxNotificationServiceProtocol {
    func post(_ name: Notification.Name, object: Any? = nil) {
        NotificationCenter.default.post(name: name, object: object)
    }

    func observe(_ name: Notification.Name) -> Observable<Notification> {
        NotificationCenter.default.rx.notification(name)
    }
}
