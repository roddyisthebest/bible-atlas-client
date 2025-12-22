//
//  AppVersion.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/22/25.
//

import Foundation

enum AppVersion {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    static var displayText: String {
        "\(version) (\(build))"
    }
}
