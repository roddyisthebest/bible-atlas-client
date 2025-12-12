//
//  ShareItemSourceViewTests.swift
//  BibleAtlasTests
//
//  Created by 배성연 on 12/6/25.
//

import XCTest
import LinkPresentation
@testable import BibleAtlas

final class ShareItemSourceViewTests: XCTestCase {

    func test_placeholderItem_returnsURL() {
        // given
        let url = URL(string: "https://bible-atlas.app/place/123")!
        let sut = ShareItemSourceView(url: url, title: "Test Place", image: nil)

        // when
        let placeholder = sut.activityViewControllerPlaceholderItem(UIActivityViewController(activityItems: [], applicationActivities: nil))

        // then
        guard let placeholderURL = placeholder as? URL else {
            XCTFail("Placeholder item is not URL")
            return
        }
        XCTAssertEqual(placeholderURL, url)
    }

    func test_itemForActivityType_returnsURL() {
        // given
        let url = URL(string: "https://bible-atlas.app/place/123")!
        let sut = ShareItemSourceView(url: url, title: "Test Place", image: nil)

        // when
        let item = sut.activityViewController(
            UIActivityViewController(activityItems: [], applicationActivities: nil),
            itemForActivityType: .postToTwitter // 임의의 타입
        )

        // then
        guard let itemURL = item as? URL else {
            XCTFail("Item is not URL")
            return
        }
        XCTAssertEqual(itemURL, url)
    }

    func test_linkMetadata_setsTitleAndURLs_andIconWhenImageProvided() {
        // given
        let url = URL(string: "https://bible-atlas.app/place/123")!
        let title = "예루살렘 (Jerusalem)"

        // 1x1 투명 이미지 하나 생성
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }

        let sut = ShareItemSourceView(url: url, title: title, image: image)

        // when
        let metadata = sut.activityViewControllerLinkMetadata(
            UIActivityViewController(activityItems: [], applicationActivities: nil)
        )

        // then
        XCTAssertNotNil(metadata, "metadata should not be nil")

        XCTAssertEqual(metadata?.title, title)
        XCTAssertEqual(metadata?.originalURL, url)
        XCTAssertEqual(metadata?.url, url)

        // iconProvider 가 설정되었는지 확인
        XCTAssertNotNil(metadata?.iconProvider, "iconProvider should be set when image is provided")
    }

    func test_linkMetadata_withoutImage_hasNoIconProvider() {
        // given
        let url = URL(string: "https://bible-atlas.app/place/456")!
        let title = "갈릴리 호수 (Sea of Galilee)"
        let sut = ShareItemSourceView(url: url, title: title, image: nil)

        // when
        let metadata = sut.activityViewControllerLinkMetadata(
            UIActivityViewController(activityItems: [], applicationActivities: nil)
        )

        // then
        XCTAssertNotNil(metadata)
        XCTAssertEqual(metadata?.title, title)
        XCTAssertEqual(metadata?.originalURL, url)
        XCTAssertEqual(metadata?.url, url)
        XCTAssertNil(metadata?.iconProvider, "iconProvider should be nil when image is nil")
    }
}
