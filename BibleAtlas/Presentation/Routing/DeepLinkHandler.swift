//
//  DeepLinkHandler.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/24/25.
//

import Foundation
// Layer: Presentation > Routing

protocol DeepLinkHandling {
    func handle(url: URL)
    func handle(userActivity: NSUserActivity)
}

final class DeepLinkHandler: DeepLinkHandling {
    private let parser: DeepLinkParser
    private let mapper: DeepLinkToBottomSheetMapper
    private weak var navigator: BottomSheetNavigator?
    private weak var analytics: AnalyticsLogging?

    init(parser: DeepLinkParser,
         mapper: DeepLinkToBottomSheetMapper,
         navigator: BottomSheetNavigator,
         analytics: AnalyticsLogging? = nil) {
        self.parser = parser
        self.mapper = mapper
        self.navigator = navigator
        self.analytics = analytics
    }

    func handle(url: URL) {
        guard let link = parser.parse(url: url),
              let type = mapper.map(link) else { return }
        navigator?.present(type)
        analytics?.log(AnalyticsEvents.deepLinkOpen(source: "universal_link", type: type.stringValue))
    }

    func handle(userActivity: NSUserActivity) {
        guard let link = parser.parse(userActivity: userActivity),
              let type = mapper.map(link) else { return }
        navigator?.present(type)
        analytics?.log(AnalyticsEvents.deepLinkOpen(source: "universal_link", type: type.stringValue))

    }
}
