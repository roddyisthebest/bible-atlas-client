//
//  DeepLinkParser.swift
//  BibleAtlas
//
//  Created by 배성연 on 12/24/25.
//

import Foundation

// Layer: Data > DeepLink

protocol DeepLinkParser {
    func parse(url: URL) -> DeepLink?
    func parse(userActivity: NSUserActivity) -> DeepLink?
}

/// Default implementation that parses custom scheme and universal links into DeepLink.
final class DefaultDeepLinkParser: DeepLinkParser {

    func parse(url: URL) -> DeepLink? {
        // Support custom scheme (app), universal links, and Kakao custom scheme.
        guard let scheme = url.scheme else { return nil }
        let lowerScheme = scheme.lowercased()
        let isKakaoScheme = lowerScheme.hasPrefix("kakao")

        let allowedSchemes: Set<String> = ["bibleatlas", "https", "http"]
        guard isKakaoScheme || allowedSchemes.contains(lowerScheme) else { return nil }

        // Kakao Link: kakao{appKey}://kakaolink?placeId=...&src=...
        if isKakaoScheme {
            guard url.host?.lowercased() == "kakaolink" else { return nil }
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let items = components?.queryItems ?? []
            let placeId = items.first(where: { $0.name == "placeId" })?.value
            if let id = placeId, !id.isEmpty {
                return .placeDetail(id: id)
            }
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        let query: (String) -> String? = { name in items.first(where: { $0.name == name })?.value }

        let paths = url.pathComponents.filter { $0 != "/" }
        guard let first = paths.first else {
            // No path -> treat as home if scheme/host matches
            return .home
        }

        switch first.lowercased() {
        case "home":
            return .home

        case "place":
            if paths.count >= 2 { return .placeDetail(id: paths[1]) }
            return nil

        case "bible":
            if paths.count >= 2 { return .bibleBook(book: paths[1]) }
            return nil

        case "verse":
            if paths.count >= 2 {
                let book = paths[1]
                let keyword = query("keyword") ?? ""
                let placeName = query("place")
                return .bibleVerseDetail(book: book, keyword: keyword, placeName: placeName)
            }
            return nil

        case "type":
            if paths.count >= 2 { return .placesByType(typeName: paths[1]) }
            return nil

        case "character":
            if paths.count >= 2 { return .placesByCharacter(name: paths[1]) }
            return nil

        case "mypage":
            return .myPage

        case "recent":
            return .recentSearches

        case "popular":
            return .popularPlaces

        case "bibles":
            return .bibles

        case "place-types":
            return .placeTypes

        case "place-characters":
            return .placeCharacters

        case "account":
            return .accountManagement

        case "report":
            return .report

        default:
            return nil
        }
    }

    func parse(userActivity: NSUserActivity) -> DeepLink? {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            return parse(url: url)
        }
        return nil
    }
}

