//
//  RegistrationView.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/26.
//

import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmedPassword = ""
    @State private var passwordsMatch = false
    
    var body: some View {
        VStack{
            Spacer()
            
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding()
            
            VStack(spacing: 8){
                TextField("メールアドレス", text: $email)
                    .autocapitalization(.none)
                    .font(.subheadline)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                
                ZStack(alignment: .trailing){
                    SecureField("パスワード", text: $password)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    // パスワードに一致・不一致によって表示判断
                    // 一致判定はpasswordsMatchにより変更
                    if !password.isEmpty && !confirmedPassword.isEmpty {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passwordsMatch ? .green : .red)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, 24)
                
                ZStack(alignment: .trailing){
                    SecureField("パスワード", text: $confirmedPassword)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    // パスワードに一致・不一致によって表示判断
                    if !password.isEmpty && !confirmedPassword.isEmpty {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passwordsMatch ? .green : .red)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, 24)
                //パスワード一致チェック
                .onChange(of: confirmedPassword) { oldValue, newValue in
                    passwordsMatch = newValue == password
                }
            }
            
            // サインアップボタン
            Button { signUp() } label: {
                Text("サインアップ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 352, height: 44)
                    .background(Color(.systemBlue))
                    .cornerRadius(8)
            }
            .disabled(!formIsValid)
            .opacity(formIsValid ? 1.0 : 0.5)
            .padding(.vertical)
            
            Spacer()
            
            Divider()
            
            Button { dismiss() } label: {
                HStack(spacing: 3) {
                    Text("すでにアカウントを持っていませんか？")
                    
                    Text("サインイン")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            .padding(.vertical, 16)
        }
    }
}

private extension RegistrationView {
    func signUp() {
        Task {
            await authManager.signUp(email: email, password: password)
            dismiss()
        }
    }
    
    var formIsValid: Bool {
        return email.isValidEmail() && passwordsMatch
    }
}
