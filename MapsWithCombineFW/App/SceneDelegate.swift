//
//  SceneDelegate.swift
//  MapsWithCombineFW
//
//  Created by arturs on 16/11/2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowsScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowsScene)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mapController = storyboard.instantiateViewController(identifier: "MapViewController") { coder in
            return MapViewController(coder: coder, mapViewModel: MapViewModel(manager: ConnectionManager(service: TCPCommunicatorMock())))
        }
        
        window.rootViewController = mapController
        
        self.window = window
        window.makeKeyAndVisible()
    }
}

