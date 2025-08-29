//
//  FirebaseService.swift
//  SitterApp
//
//  Created by Ibrahim Mo Gedami on 25/08/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseService: ObservableObject {
    
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private var authHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(user))
            }
        }
    }
    
    func signUp(email: String, password: String, userType: String, name: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": email,
                    "userType": userType,
                    "name": name,
                    "createdAt": Timestamp(date: Date())
                ]
                
                self?.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(user))
                    }
                }
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - Call Management
    func createCall(from callerId: String, to receiverId: String, channelName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let timeoutAt = Date().addingTimeInterval(Constants.callTimeout)
        let callData: [String: Any] = [
            "callerId": callerId,
            "receiverId": receiverId,
            "channelName": channelName,
            "status": "calling",
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "callType": "voice",
            "timeoutAt": Timestamp(date: timeoutAt)
        ]
        
        db.collection("calls").document(channelName).setData(callData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func listenForIncomingCalls(userId: String, completion: @escaping (Call) -> Void) -> ListenerRegistration {
        return db.collection("calls")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "calling")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    let data = document.data()
                    if let call = Call(from: data, id: document.documentID) {
                        if let timeoutAt = call.timeoutAt, Date() > timeoutAt {
                            self.updateCallStatus(channelName: call.channelName, status: "timeout") { _ in }
                        } else {
                            completion(call)
                        }
                    }
                }
            }
    }
    
    func updateCallStatus(channelName: String, status: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("calls").document(channelName).updateData([
            "status": status,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func endCall(channelName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        updateCallStatus(channelName: channelName, status: "ended", completion: completion)
    }
    
    func listenForCallStatus(channelName: String, completion: @escaping (String) -> Void) -> ListenerRegistration {
        return db.collection("calls").document(channelName)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(),
                      let status = data["status"] as? String else { return }
                completion(status)
            }
    }
    
    func waitForCallAcceptance(channelName: String, completion: @escaping (Result<Bool, Error>) -> Void) -> ListenerRegistration {
        return db.collection("calls").document(channelName)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data(),
                      let status = data["status"] as? String else {
                    completion(.success(false))
                    return
                }
                
                if status == "accepted" {
                    completion(.success(true))
                } else if status == "rejected" || status == "ended" || status == "timeout" {
                    completion(.success(false))
                }
            }
    }
    
    // MARK: - User Management
    func getUserProfile(userId: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = snapshot?.data(),
                      let profile = UserProfile(from: data) {
                completion(.success(profile))
            } else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
            }
        }
    }
    
    func getAvailableUsers(userType: String, completion: @escaping (Result<[UserProfile], Error>) -> Void) {
        db.collection("users")
            .whereField("userType", isEqualTo: userType)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let profiles = snapshot?.documents.compactMap { document -> UserProfile? in
                        UserProfile(from: document.data())
                    } ?? []
                    completion(.success(profiles))
                }
            }
    }
    
    func getCallInfo(channelName: String, completion: @escaping (Result<Call, Error>) -> Void) {
        db.collection("calls").document(channelName).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = snapshot?.data(),
                      let call = Call(from: data, id: snapshot?.documentID ?? "") {
                completion(.success(call))
            } else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Call not found"])))
            }
        }
    }

    // MARK: - Timeout Management
    func checkForCallTimeouts() {
        let now = Timestamp(date: Date())
        db.collection("calls")
            .whereField("status", isEqualTo: "calling")
            .whereField("timeoutAt", isLessThan: now)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    self.updateCallStatus(channelName: document.documentID, status: "timeout") { _ in }
                }
            }
    }
    
    func getAvailableSitters(completion: @escaping (Result<[UserProfile], Error>) -> Void) {
        db.collection("users")
            .whereField("userType", isEqualTo: "sitter")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let profiles = snapshot?.documents.compactMap { document -> UserProfile? in
                        UserProfile(from: document.data())
                    } ?? []
                    completion(.success(profiles))
                }
            }
    }
    
    // MARK: - Bidirectional Call Management
    func listenForAnyIncomingCalls(userId: String, completion: @escaping (Call) -> Void) -> ListenerRegistration {
        return db.collection("calls")
            .whereField("status", isEqualTo: "calling")
            .whereFilter(Filter.orFilter([
                Filter.whereField("receiverId", isEqualTo: userId),
                Filter.whereField("callerId", isEqualTo: userId)
            ]))
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    let data = document.data()
                    if let call = Call(from: data, id: document.documentID) {
                        // Only notify if current user is the receiver
                        if call.receiverId == userId {
                            completion(call)
                        }
                    }
                }
            }
    }
    
    func getActiveCall(userId: String, completion: @escaping (Call?) -> Void) -> ListenerRegistration {
        return db.collection("calls")
            .whereField("status", in: ["calling", "accepted"])
            .whereFilter(Filter.orFilter([
                Filter.whereField("receiverId", isEqualTo: userId),
                Filter.whereField("callerId", isEqualTo: userId)
            ]))
            .addSnapshotListener { snapshot, error in
                guard let document = snapshot?.documents.first else {
                    completion(nil)
                    return
                }
                
                let data = document.data()
                if let call = Call(from: data, id: document.documentID) {
                    completion(call)
                } else {
                    completion(nil)
                }
            }
    }
    
    func getCallerProfile(call: Call, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let callerId = call.callerId
        getUserProfile(userId: callerId, completion: completion)
    }
    
    func getReceiverProfile(call: Call, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let receiverId = call.receiverId
        getUserProfile(userId: receiverId, completion: completion)
    }
    
    func getAvailableParents(completion: @escaping (Result<[UserProfile], Error>) -> Void) {
        db.collection("users")
            .whereField("userType", isEqualTo: "parent")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let profiles = snapshot?.documents.compactMap { document -> UserProfile? in
                        UserProfile(from: document.data())
                    } ?? []
                    completion(.success(profiles))
                }
            }
    }
    
    func listenForCallStateChanges(userId: String, completion: @escaping (Call, String) -> Void) -> ListenerRegistration {
        return db.collection("calls")
            .whereFilter(Filter.orFilter([
                Filter.whereField("callerId", isEqualTo: userId),
                Filter.whereField("receiverId", isEqualTo: userId)
            ]))
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                for document in documents {
                    let data = document.data()
                    if let call = Call(from: data, id: document.documentID),
                       let status = data["status"] as? String {
                        completion(call, status)
                    }
                }
            }
    }
    
}
