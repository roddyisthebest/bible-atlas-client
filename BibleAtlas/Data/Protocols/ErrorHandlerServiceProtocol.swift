//
//  ErrorHandlerServiceProtocol.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/26/25.
//

import Foundation

protocol ErrorHandlerServiceProtocol {
    func logoutDueToExpiredSession() async
}
