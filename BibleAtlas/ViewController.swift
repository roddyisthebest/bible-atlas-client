//
//  ViewController.swift
//  BibleAtlas
//
//  Created by 배성연 on 2/3/25.
//

import UIKit

class ViewController: UIViewController {

    
    func testLoginAPI() {
           let loginURL = URL(string: "https://api.bible-atlas.com/auth/login")!
           var request = URLRequest(url: loginURL)
           request.httpMethod = "POST"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           
           let loginPayload: [String: Any] = [
               "userId": "testUser",
               "password": "securePassword"
           ]
           
           do {
               let bodyData = try JSONSerialization.data(withJSONObject: loginPayload, options: [])
               request.httpBody = bodyData
               
               let task = URLSession.shared.dataTask(with: request) { data, response, error in
                   guard let data = data, error == nil else {
                       print("❌ Error: \(error?.localizedDescription ?? "Unknown error")")
                       return
                   }
                   
                   if let httpResponse = response as? HTTPURLResponse {
                       print("📡 Response Status Code: \(httpResponse.statusCode)")
                   }
                   
                   if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                       print("✅ Mock API Response:", jsonResponse)
                   } else {
                       print("⚠️ Failed to decode JSON response")
                   }
               }
               
               task.resume()
           } catch {
               print("❌ JSON Encoding Error: \(error.localizedDescription)")
           }
       }
    override func viewDidLoad() {
        super.viewDidLoad()
        testLoginAPI();
        // Do any additional setup after loading the view.
    }


}

