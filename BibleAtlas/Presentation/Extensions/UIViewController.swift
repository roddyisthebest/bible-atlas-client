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
    

    @objc private func dismissKeyboardGlobally() {
        DispatchQueue.main.async {
            self.view.endEditing(true)
        }
    }
    
}
