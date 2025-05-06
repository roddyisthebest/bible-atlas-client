//
//  PassthroughDimmedView.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/5/25.
//

import Foundation
import UIKit

final class PassthroughDimmedView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
         return false // 완전히 터치 무시
     }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}
