//
//  LoginView.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/25.
//

import SwiftUI
//

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack{
            VStack{
                Spacer()
                
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding()
                
                VStack(spacing: 8){
                    TextField("メールアドレス", text: $email)
                        .autocapitalization(.none) // 大文字にならないようにしている
                        .font(.subheadline)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                    
                    SecureField("パスワード", text: $password)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                }
                
                Button { signIn() } label: {
                    Text("ログイン")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 352, height: 44)
                        .background(Color(.systemBlue))
                        .cornerRadius(8)
                }
                .disabled(!formIsValid) // 入力が正しくないとボタンが押せなくする
                .opacity(formIsValid ? 1.0 : 0.5) // 有効なら100,無効なら50にしてわかりやすくしている
                .padding(.vertical)

                Spacer()
                
                Divider()
                
                // 新規登録画面への遷移
                NavigationLink {
                    RegistrationView()
                        .navigationBarBackButtonHidden()
                } label: {
                    HStack(spacing: 3){
                        Text("アカウントを持っていませんか？")
                        
                        Text("サインアップ")
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 16)
            }
        }
    }
}

private extension LoginView {
    // ここのViewでは入力値を渡すだけ
    func signIn() {
        Task { await authManager.signIn(email: email, password: password) }
    }
    
    // 入力チェック（メールが正しい形式かつパスワードがからでないとき）
    var formIsValid: Bool {
        return email.isValidEmail() && !password.isEmpty
    }
}

extension String {
    // メールアドレスの正規表現チェック
    func isValidEmail() -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }
}
