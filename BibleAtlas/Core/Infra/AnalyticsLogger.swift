//
//  AnalyticsLogger.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/27/25.
//

import Foundation
import FirebaseAnalytics

protocol AnalyticsLogging: AnyObject{
  func log(_ event: AnalyticsEvent)
  func setUserId(_ id: String?)
  func setUserProperty(_ value: String?, for name: String)
}

final class FirebaseAnalyticsLogger: AnalyticsLogging {
  func log(_ event: AnalyticsEvent) {
    Analytics.logEvent(event.name, parameters: event.params)
  }

  func setUserId(_ id: String?) {
    Analytics.setUserID(id)
  }

  func setUserProperty(_ value: String?, for name: String) {
    Analytics.setUserProperty(value, forName: name)
  }
}

struct AnalyticsEvent {
  let name: String
  let params: [String: Any]?

  init(_ name: String, _ params: [String: Any]? = nil) {
    self.name = name
    self.params = params
  }
}



enum AnalyticsEvents {
  static func screen(_ name: String) -> AnalyticsEvent {
    .init("screen_view_custom", ["screen_name": name])
  }

  static func deepLinkOpen(source: String, type: String) -> AnalyticsEvent {
    .init("deeplink_open", ["source": source, "type": type])
  }

  static func placeOpen(placeId: String) -> AnalyticsEvent {
    .init("place_open", ["place_id": placeId])
  }

  static func shareTap(placeId: String, channel: String) -> AnalyticsEvent {
    .init("share_tap", ["place_id": placeId, "channel": channel])
  }

  static func apiError(endpoint: String, code: Int) -> AnalyticsEvent {
    .init("api_error", ["endpoint": endpoint, "code": code])
  }
}
