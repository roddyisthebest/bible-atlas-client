//
//  UIViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 5/1/25.
//

import UIKit

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        } else {
            return self
        }
    }
    
    func setupDismissKeyboardOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboardGlobally))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    func showErrorAlert(message: String?) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    func showDefaultAlert(
            message: String,
            buttonTitle: String = "확인",
            animated: Bool = true,
            completion: (() -> Void)? = nil,
            handler: ((UIAlertAction) -> Void)? = nil
        ) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.view.window != nil else { return }
                
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: buttonTitle, style: .default, handler: handler)
                alert.addAction(action)
                
                self.present(alert, animated: animated, completion: completion)
            }
        }

    @objc private func dismissKeyboardGlobally() {
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
    }
    
}
