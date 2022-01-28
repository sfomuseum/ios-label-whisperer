//
//  AppDelegate.swift
//  LableWhisperer
//
//  Created by asc on 11/12/21.
//

import UIKit
import AccessionNumbers
import Network

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var definition_files: DefinitionFiles!
    var network_available: Bool!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        let monitor = NWPathMonitor()
        network_available = true
        
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { path in
            
            if path.status == .satisfied {
                self.network_available = true
            } else {
                self.network_available = false
            }
            
            // NotificationCenter.default.post(name: Notification.Name("networkAvailable"), object: self.network_available)
        }
        
        do {
            let d = try DefinitionFiles()
            definition_files = d
        } catch (let error) {
            print("Failed to create definition files \(error)")
            return false
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

