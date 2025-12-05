//
//  AppUtility.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 27/06/2025.
//

#if os(iOS)
import SwiftUI

enum AppUtility {
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = orientation
    }

    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateTo: UIInterfaceOrientation) {
        lockOrientation(orientation)
        
        UIApplication.shared.connectedScenes.forEach { scene in
            if let windowScene = scene as? UIWindowScene {
                AppDelegate.orientationLock = orientation
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
                
                windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
    }
}
#endif
