//
//  AnalyticsLoggerTests.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/27/25.
//

import XCTest
@testable import BibleAtlas

final class AnalyticsLoggerTests: XCTestCase {

    // Simple spy to capture calls
    final class SpyLogger: AnalyticsLogging {
        var logged: AnalyticsEvent?
        var setUserIdValue: String?
        var setUserPropertyValue: (value: String?, name: String)?

        func log(_ event: AnalyticsEvent) { logged = event }
        func setUserId(_ id: String?) { setUserIdValue = id }
        func setUserProperty(_ value: String?, for name: String) { setUserPropertyValue = (value, name) }
    }

    func test_shareTap_eventBuilder_buildsCorrectEvent() {
        // given
        let placeId = "pid-123"
        let channel = "kakao"

        // when
        let event = AnalyticsEvents.shareTap(placeId: placeId, channel: channel)

        // then
        XCTAssertEqual(event.name, "share_tap")
        let params = event.params as? [String: AnyHashable]
        XCTAssertEqual(params?["place_id"] as? String, placeId)
        XCTAssertEqual(params?["channel"] as? String, channel)
    }

    func test_firebaseAnalyticsLogger_forwardsLog_callsInjectedClosure() {
        // given: inject spies for Firebase static functions
        var received: (name: String, params: [String: Any]?)?
        let logger = FirebaseAnalyticsLogger(
            logEvent: { name, params in received = (name, params) },
            setUserID: { _ in },
            setUserProperty: { _, _ in }
        )

        let event = AnalyticsEvents.shareTap(placeId: "abc", channel: "line")

        // when
        logger.log(event)

        // then
        XCTAssertEqual(received?.name, "share_tap")
        let params = received?.params as? [String: AnyHashable]
        XCTAssertEqual(params?["place_id"] as? String, "abc")
        XCTAssertEqual(params?["channel"] as? String, "line")
    }

    func test_firebaseAnalyticsLogger_forwardsUserId_andUserProperty() {
        // given
        var gotUserId: String?
        var gotUserProperty: (String?, String)?
        let logger = FirebaseAnalyticsLogger(
            logEvent: { _, _ in },
            setUserID: { gotUserId = $0 },
            setUserProperty: { value, name in gotUserProperty = (value, name) }
        )

        // when
        logger.setUserId("user-1")
        logger.setUserProperty("pro", for: "tier")

        // then
        XCTAssertEqual(gotUserId, "user-1")
        XCTAssertEqual(gotUserProperty?.0, "pro")
        XCTAssertEqual(gotUserProperty?.1, "tier")
    }
}
