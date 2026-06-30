//
//  LinkAccountView.swift
//  AuthSDK
//
//  Created by X on 4/21/25.
//

import SwiftUI

public struct LinkAccountView: View {
    
    @StateObject var viewModel: LinkAccountViewModel
    
    private let onSuccess: (AuthSessionResponse) -> Void
    private let onFailure: (AuthErrorResponse) -> Void
    private let onClose: () -> Void
    
    public init(authManager: AuthManager,
                //                presentedScreen: Binding<PopupScreen?>,
                guestToken: String,
                onSuccess: @escaping (AuthSessionResponse) -> Void,
                onFailure:  @escaping (AuthErrorResponse) -> Void,
                onClose:  @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: LinkAccountViewModel(
            authManager: authManager,
            guestToken: guestToken,
            //            presentedScreen: presentedScreen,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onClose: onClose
        ))
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.onClose = onClose
    }
    
    public var body: some View {
        GeometryReader { geo in
            content
                .preferredColorScheme(.light)
                .frame(
                    width: geo.size.width,
                    height: geo.size.height,
                    alignment: .center
                )
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
                .popup(
                    item: $viewModel.presentedScreen
                ) { screen, dismiss in
                    presentPopup(for: screen)
                }
        }

    }
    
    @ViewBuilder
    private var content: some View {
        SquareContainer(
            onCloseClick: {
                onClose()
            },
            content: {
                VStack(content: {
                    Text(.sdkAsset("link_to_accounts_title"))
                        .font(AppFont.fsClanNarrowUltra.of(size: 20))
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Text(.sdkAsset("link_to_accounts_subtitle"))
                        .font(AppFont.poppinsLight.of(size: 12))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryText)
                        .padding(.horizontal, 48)
                    
                    HStack {
                        Spacer()
                        Spacer()
                        Spacer()
                        
                        SecondaryButton(
                            action: {
                                viewModel.linkToGoogleAccount()
                            },
                            content: {
                                HStack {
                                    Image(sdkAsset: "IconGoogle")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                    
                                    Text(.sdkAsset("google"))
                                        .foregroundColor(.white)
                                        .font(AppFont.poppinsLight.of(size: 8))
                                    
                                    
                                }
                            }
                        )
                        .layoutPriority(1)
                        
                        SecondaryButton(
                            action: {
                                viewModel.linkToFacebookAccount()
                            },
                            content: {
                                HStack {
                                    Image(sdkAsset: "IconFacebook")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                    
                                    Text(.sdkAsset("facebook"))
                                        .foregroundColor(.white)
                                        .font(AppFont.poppinsLight.of(size: 8))
                                }
                            }
                        )
                        .layoutPriority(1)
                        
                        SecondaryButton(action: {
                            viewModel.presentedScreen = .register(type: .linkToNewAccount)
                        }, content: {
                            HStack {
                                Image(sdkAsset: "IconPhone")
                                    .resizable()
                                    .renderingMode(.original)
                                    .frame(width: 16, height: 16)
                                
                                Text(.sdkAsset("phone_number"))
                                    .foregroundColor(.white)
                                    .font(AppFont.poppinsLight.of(size: 8))
                            }
                        })
                        .layoutPriority(1)
                        
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical)
                    
                    if let errorMessageKey = viewModel.errorMessageKey {
                        ValidationMessageText(textKey: errorMessageKey, size: 8)
                    }
                }
                )
            }
        )
    }
    
    @ViewBuilder
    private func presentPopup(for screen: PopupScreen) -> some View {
        switch screen {
        case .register(let flowType):
            PhoneNumberInputView(
                flowType: flowType,
                presentedScreen: $viewModel.presentedScreen,
                authManager: viewModel.authManager
            )
            
        case .otpInput(let flowType, let phoneNumber, let otpSendableResponse, _):
            OTPInputView(
                flowType: flowType,
                phoneNumber: phoneNumber,
                otpSendableResponse: otpSendableResponse,
                presentedScreen: $viewModel.presentedScreen,
                authManager: viewModel.authManager,
                onSuccess: { phoneNumber, otpToken in
                    viewModel.presentedScreen = .passwordInput(
                        type: flowType,
                        phoneNumber: phoneNumber,
                        otpVerifiedToken: otpToken,
                        accountInformation: nil
                    )
                },
                onFailure: { authError in
                    debugPrint("OTP verification failed with message \(authError)")
                }
            )
        case .passwordInput(let flowType, let phoneNumber, let otpVerifiedToken, let accountInformation):
            PasswordInputView(
                flowType: flowType,
                phoneNumber: phoneNumber,
                otpVerifiedToken: otpVerifiedToken,
                accountInformation: accountInformation,
                presentedScreen: $viewModel.presentedScreen,
                authManager: viewModel.authManager,
                onSuccess: { flowType, session in
                    debugPrint("set up password success \(flowType) \(String(describing: session))")
                    if let session = session {
                        self.onSuccess(session)
                    }
                },
                onFailure: { authErrorResponse in
                    debugPrint("set up password failure \(authErrorResponse)")
                    self.onFailure(authErrorResponse)
                }
            )
        case .updateAccountInfo:
            EmptyView()
        default:
            EmptyView()
            //        case .linkAccount(let guestToken):
            //            LinkAccountView(
            //                authManager: viewModel.authManager,
            //                presentedScreen: $viewModel.presentedScreen,
            //                guestToken: guestToken,
            //                onSuccess: { authSession in debugPrint("link account success \(authSession)")},
            //                onFailure: {authError in },
            //                onClose: {
            //
            //                }
            //            )
        }
    }
}


#Preview {
    LinkAccountView(
        authManager: DefaultAuthManager.Builder().build(),
        //        presentedScreen:.constant(nil),
        guestToken: "",
        onSuccess: { session in debugPrint("Success") },
        onFailure: { authError in debugPrint("Failure") },
        onClose: {
            
        }
    )
}
