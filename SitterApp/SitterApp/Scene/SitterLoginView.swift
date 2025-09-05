//
//  SitterLoginView.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 26/08/2025.
//

import Foundation
import SwiftUI

struct SitterLoginView: View {
    
    @EnvironmentObject var authService: FirebaseService
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignUp = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sitter App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Sign In") {
                    signIn()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Create Account") {
                    isShowingSignUp = true
                }
                .foregroundColor(.blue)
            }
            .padding()
        }
        .sheet(isPresented: $isShowingSignUp) {
            SitterSignUpView()
        }
    }
    
    private func signIn() {
        authService.signIn(email: email, password: password) { result in
            switch result {
            case .success:
                errorMessage = ""
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
}

struct SitterSignUpView: View {
    
    @EnvironmentObject var authService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Sitter Account")
                    .font(.title2)
                
                VStack(spacing: 15) {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button("Sign Up") {
                        signUp()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
    }
    
    private func signUp() {
        authService.signUp(email: email, password: password, userType: .sitter, name: name) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

}
