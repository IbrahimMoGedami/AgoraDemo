//
//  ParentHomeView.swift
//  ParentApp
//
//  Created by Ibrahim Mo Gedami on 25/08/2025.
//

import SwiftUI

struct ParentHomeView: View {
    
    @EnvironmentObject var authService: FirebaseService
    @EnvironmentObject var agoraService: AgoraService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                if agoraService.isInCall {
                    CallView()
                } else {
                    ParentMainView()
                }
            } else {
                LoginView()
            }
        }
    }
    
}
