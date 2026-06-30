//
//  PasswordInputView.swift
//  AuthSDK
//

import SwiftUI


struct PasswordInputView: View {
    @StateObject var viewModel: PasswordInputViewModel
    @FocusState private var focusedField: PasswordInputViewModel.FocusField?
    @SwiftUI.Environment(\.verticalSizeClass) var verticalSizeClass

    init(flowType: FlowType,
         phoneNumber: String,
         otpVerifiedToken: String,
         accountInformation: AccountInformation? = nil,
         stepIndex: Int = 3,
         totalStepCount: Int = 3,
         presentedScreen: Binding<PopupScreen?>,
         authManager: AuthManager,
         onSuccess: @escaping (FlowType, AuthSessionResponse?) -> Void,
         onFailure: @escaping (AuthErrorResponse) -> Void) {
        _viewModel = StateObject(wrappedValue: PasswordInputViewModel(
            flowType: flowType,
            phoneNumber: phoneNumber,
            otpVerifiedToken: otpVerifiedToken,
            accountInformation: accountInformation,
            stepIndex: stepIndex,
            totalStepCount: totalStepCount,
            presentedScreen: presentedScreen,
            authManager: authManager,
            onSuccess: onSuccess,
            onFailure: onFailure
        ))
    }

    var body: some View {
        
        GeometryReader { geo in
            let isLandscape = verticalSizeClass == .compact
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let width = UIScreen.main.bounds.size.width
            let height = UIScreen.main.bounds.size.height
            let minValue = min(width, height, CGFloat((isPad ? 440 : Int.max)))
            let contentWidth = isLandscape ? minValue*0.8*0.9 : minValue
            let contentHeight = isLandscape ? minValue*0.9 : minValue*1.2
            
            
            content(
                width: contentWidth,
                height: contentHeight
            )
            .preferredColorScheme(.light)
            .frame(
                width: geo.size.width,
                height: geo.size.height,
                alignment: .center
            )
            .navigationBarHidden(true)
            .background(Color.black.opacity(0.5))
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ZStack {
                            Color.clear
                                .ignoresSafeArea()
                            ProgressView(.sdkAsset("loading"))
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                                .background(Color.sdkPrimaryText)
                                .cornerRadius(10)
                                .shadow(radius: 10)
                        }
                    }
                }
            )
        }
        
    }
    
    
    @ViewBuilder
    private func content(width: CGFloat, height: CGFloat) -> some View {
        AuthContainer(
            wid: width,
            hei: height,
            onCloseClick: {
                viewModel.presentedScreen = nil
            },
            content: {
                let _ = verticalSizeClass == .regular
                VStack {
                    Text(.sdkAsset("step_x_of_y", viewModel.stepIndex, viewModel.totalStepCount))
                        .font(AppFont.fsClanNarrowUltra.of(size: 14))
                        .foregroundColor(.secondaryText)
                        .padding(.top, 24)
                        .padding(.bottom, 2)
                    
                    Text(viewModel.flowType.passwordTitle)
                        .font(AppFont.fsClanNarrowUltra.of(size: 16))
                        .foregroundColor(.primaryText)
                        .padding(.bottom, 8)
                    
                    VStack (alignment: .leading ,spacing: 2) {
                        Text(.sdkAsset("password"))
                            .font(AppFont.poppinsLight.of(size: 12))
                            .foregroundColor(.secondaryText)
                            .padding(.bottom, 2)
                        
                        SecureInputView(
                            .sdkAsset("enter_your_password"),
                            text: $viewModel.password
                        )
                        .submitLabel(.next)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            focusedField = .confirmPassword
                        }
                        .onChange(of: viewModel.password) { newValue in
                            viewModel.password = newValue.replacingOccurrences(of: " ", with: "")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    
                    VStack (alignment: .leading ,spacing: 2) {
                        Text(.sdkAsset("re_enter_password"))
                            .font(AppFont.poppinsLight.of(size: 12))
                            .foregroundColor(.secondaryText)
                            .padding(.bottom, 2)
                        
                        SecureInputView(.sdkAsset("reenter_your_password"), text: $viewModel.confirmPassword)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .confirmPassword)
                            .onSubmit {
                                if(viewModel.isSubmitEnabled) {
                                    focusedField = nil
                                    viewModel.submit()
                                }
                            }
                            .onChange(of: viewModel.confirmPassword) { newValue in
                                viewModel.confirmPassword = newValue.replacingOccurrences(of: " ", with: "")
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    PasswordVerifyView(
                        password: $viewModel.password,
                        confirmPassword: $viewModel.confirmPassword)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                                        
                    if let errorMessage = viewModel.errorMessage {
                        ValidationMessageText(
                            textKey: errorMessage
                        ).padding(.horizontal, 12)
                    }
                }
                .padding(.horizontal, 16)
//                .toolbar {
//                    ToolbarItemGroup(placement: .keyboard) {
//                        Spacer()
//                        if focusedField == .password {
//                            Button("Next") {
//                                focusedField = .confirmPassword
//                            }
//                        } else {
//                            Button("Previous") {
//                                focusedField = .password
//                            }
//                        }
//                        Button("Done") {
//                            viewModel.submit()
//                            focusedField = nil
//                        }
//                    }
//                }
//                .hideKeyboardOnTap()
            },
            footer: {
                let primaryButtonWidth = width*0.46
                PrimaryButton(
                    action: {
                        viewModel.submit()
                    },
                    label: {
                        Text(.sdkAsset("confirm"))
                    },
                    isDisabled: !viewModel.isSubmitEnabled
                )
                .frame(width: primaryButtonWidth, height: primaryButtonWidth*0.35)
            }
        )
        .hideKeyboardOnTap()
    }
}

extension PasswordInputView {
    enum AlertType: Identifiable {
        case handleSuccess(String)
        case handleFailure(String)
        
        var id: String {
            switch self {
            case .handleSuccess(let message):
                return message
            case .handleFailure(let message):
                return message
            }
        }
    }
}

private extension FlowType {
    var passwordTitle: String {
        switch self {
        case .register, .linkToNewAccount:
            return LocalizedStringKey.sdkAsset("set_password_title").toString()
        case .forgetPassword:
            return  LocalizedStringKey.sdkAsset("forget_password_title").toString()
        }
    }
    
    var passwordSubtitle: String {
        switch self {
        case .register, .linkToNewAccount:
            return "Create a secure password for your account"
        case .forgetPassword:
            return "Enter a new password for your account"
        }
    }
    
    var passwordButtonText: String {
        switch self {
        case .register:
            return "Finish Sign Up"
        case .forgetPassword:
            return "Reset Password"
        case .linkToNewAccount:
            return "Finsh Linking"
        }
    }
    
    var passwordTextInputLabel: String {
        switch self {
        case .register, .linkToNewAccount:
            return "Password"
        case .forgetPassword:
            return "New Password"
        }
    }
    
    var confirmPasswordTextInputLabel: String {
        switch self {
        case .register, .linkToNewAccount:
            return "Confirm password"
        case .forgetPassword:
            return "Confirm new password"
        }
    }
    
    var passwordPlaceholder: String {
        switch self {
        case .register, .linkToNewAccount:
            return "Enter your password"
        case .forgetPassword:
            return "Enter your new password"
        }
    }
    
    var confirmPasswordPlaceholder: String {
        switch self {
        case .register, .linkToNewAccount:
            return "Confirm your password"
        case .forgetPassword:
            return "Confirm your new password"
        }
    }
}

#Preview {
    PasswordInputView(flowType: .register,
                      phoneNumber: "0983452423",
                      otpVerifiedToken : "1345",
                      presentedScreen: .constant(nil),
                      authManager: DefaultAuthManager.Builder().build(),
                      onSuccess: { _,_ in
                            debugPrint("Success")
                      },
                      onFailure: { error in
                            debugPrint("Failure")
                      })
}
