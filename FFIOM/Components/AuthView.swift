import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager()
    @State private var showLogin = true
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.06, green: 0.06, blue: 0.12), Color(red: 0.12, green: 0.12, blue: 0.24)],
                              startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "soccerball").font(.system(size: 48)).foregroundStyle(.green)
                        Text("Fantasy Football").font(.title.bold()).fontWeight(.heavy)
                        Text("Isle of Man").font(.title2).foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 40)
                    RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                        .overlay {
                            if showLogin {
                                LoginView(username: $username, password: $password, authManager: authManager) {
                                    if let e = authManager.errorMessage { alertMessage = e; showAlert = true }
                                }
                            } else {
                                RegisterView(username: $username, password: $password, email: $email, authManager: authManager) {
                                    if let e = authManager.errorMessage { alertMessage = e; showAlert = true }
                                }
                            }
                        }
                        .frame(width: 320, height: showLogin ? 220 : 290).padding(.horizontal, 24)
                    Spacer()
                    HStack {
                        Text(showLogin ? "Don't have an account?" : "Already have an account?").foregroundStyle(.secondary)
                        Button(showLogin ? "Register" : "Log In") { withAnimation { showLogin.toggle() } }
                            .foregroundStyle(.green).fontWeight(.semibold)
                    }
                    .padding(.bottom, 40)
                }
            }
            .alert("Error", isPresented: $showAlert) { Button("OK", role: .cancel) {} } message: { Text(alertMessage) }
            .overlay { if authManager.isLoading { ProgressView().padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)) } }
        }
    }
}

struct LoginView: View {
    @Binding var username: String
    @Binding var password: String
    @ObservedObject var authManager: AuthManager
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Log In").font(.title3.bold()).padding(.top, 20)
            EditableTextField(text: $username, placeholder: "Username")
            EditableTextField(text: $password, placeholder: "Password", isSecure: true, onSubmit: { login() })
            Button(action: login) {
                Text("Log In").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color.green).foregroundColor(.white).cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }
    
    private func login() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            authManager.errorMessage = "Please fill in all fields"
            onSubmit()
            return
        }
        Task {
            let ok = await authManager.login(username: username, password: password)
            if !ok { onSubmit() }
        }
    }
}

struct RegisterView: View {
    @Binding var username: String
    @Binding var password: String
    @Binding var email: String
    @ObservedObject var authManager: AuthManager
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Create Account").font(.title3.bold()).padding(.top, 20)
            EditableTextField(text: $username, placeholder: "Username")
            EditableTextField(text: $email, placeholder: "Email")
            EditableTextField(text: $password, placeholder: "Password", isSecure: true, onSubmit: { register() })
            Button(action: register) {
                Text("Create Account & Team").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color.green).foregroundColor(.white).cornerRadius(12)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal)
    }
    
    private func register() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            authManager.errorMessage = "Please fill in all fields"
            onSubmit()
            return
        }
        Task {
            let ok = await authManager.register(username: username, password: password, email: email)
            if !ok { onSubmit() }
        }
    }
}
