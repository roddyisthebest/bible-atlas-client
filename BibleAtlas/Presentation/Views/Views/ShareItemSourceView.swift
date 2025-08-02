//
//  ShareItemSource.swift
//  BibleAtlas
//
//  Created by 배성연 on 8/2/25.
//

import LinkPresentation

final class ShareItemSourceView: NSObject, UIActivityItemSource {
    let url: URL
    let title: String
    let image: UIImage?

    init(url: URL, title: String, image: UIImage?) {
        self.url = url
        self.title = title
        self.image = image
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return url
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()


        metadata.title = title

        metadata.originalURL = url
        metadata.url = url

        if let image = image {
            metadata.iconProvider = NSItemProvider(object: image)
        }

        return metadata
    }
}

