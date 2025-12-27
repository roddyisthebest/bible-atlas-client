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
  private let _logEvent: (String, [String: Any]?) -> Void
  private let _setUserID: (String?) -> Void
  private let _setUserProperty: (String?, String) -> Void

  init(
    logEvent: @escaping (String, [String: Any]?) -> Void = { Analytics.logEvent($0, parameters: $1) },
    setUserID: @escaping (String?) -> Void = { Analytics.setUserID($0) },
    setUserProperty: @escaping (String?, String) -> Void = { Analytics.setUserProperty($0, forName: $1) }
  ) {
    self._logEvent = logEvent
    self._setUserID = setUserID
    self._setUserProperty = setUserProperty
  }

  func log(_ event: AnalyticsEvent) {
    _logEvent(event.name, event.params)
  }

  func setUserId(_ id: String?) {
    _setUserID(id)
  }

  func setUserProperty(_ value: String?, for name: String) {
    _setUserProperty(value, name)
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

