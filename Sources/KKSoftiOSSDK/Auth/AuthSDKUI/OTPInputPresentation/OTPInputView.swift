import SwiftUI

struct OTPInputView: View {
    @StateObject var viewModel: OTPInputViewModel
    @SwiftUI.Environment(\.verticalSizeClass) var verticalSizeClass
    
    init(flowType: FlowType,
         phoneNumber: String,
         otpSendableResponse: OTPSendableResponse,
         stepIndex: Int = 2,
         totalStepCount: Int = 3,
         presentedScreen: Binding<PopupScreen?>,
         authManager: any AuthManager,
         onSuccess: @escaping (String, String) -> Void,
         onFailure: @escaping (AuthErrorResponse) -> Void
    ) {
        self._viewModel = StateObject(
            wrappedValue: OTPInputViewModel(
                flowType: flowType,
                phoneNumber: phoneNumber,
                otpSendableResponse: otpSendableResponse,
                stepIndex: stepIndex,
                totalStepCount: totalStepCount,
                presentedScreen: presentedScreen,
                authManager: authManager,
                onSuccess: onSuccess,
                onFailure: onFailure
            )
        )
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
            .onAppear() {
                viewModel.requestOTP()
            }
        }
    }
    
    
    @ViewBuilder
    private func content(width: CGFloat, height: CGFloat) -> some View {
        let isPortrait = verticalSizeClass == .regular
        AuthContainer(
            wid: width,
            hei: height,
            onCloseClick: {
                viewModel.presentedScreen = nil
            },
            content: {
                VStack {
                    Text(.sdkAsset("step_x_of_y", viewModel.stepIndex, viewModel.totalStepCount))
                        .font(AppFont.fsClanNarrowUltra.of(size: 15))
                        .foregroundColor(.secondaryText)
                        .foregroundColor(.sdkPrimaryReverseText)
                        .padding(.bottom, 2)
                    
                    Text(.sdkAsset("enter_otp"))
                        .font(AppFont.fsClanNarrowUltra.of(size: 16))
                        .foregroundColor(.primaryText)
                        .textCase(.uppercase)
                        .padding(.bottom, 12)
                        
                    Text(.sdkAsset("enter_otp_subtitle", viewModel.phoneNumber))
                        .font(AppFont.poppinsRegular.of(size: 10))
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 17)
                        
                    OTPTextField(otpText: $viewModel.otpText)
                        .padding(.top, 4)
                        .padding(.horizontal, 16)
                        .disabled(viewModel.isOTPRequestManyTime)
                        .padding(.bottom, 13)
                    
//                    if viewModel.isAccountExisted == false {
                        MeasuredBox {
                            if viewModel.isOTPExpired {
                                otpExpiredView
                                    .padding(.top, 4)
                                    .padding(.horizontal, 32)
                                    .layoutPriority(1)
                            } else {
                                let message: LocalizedStringKey? = viewModel.errorMessage
                                ValidationMessageText(textKey: message, size: 12, isValid: false)
                                    .layoutPriority(1)
                                    .frame(height: 24)
                                resendOTPView
                                    .padding(.top, 4)
                                    .padding(.horizontal, 32)
                                    .layoutPriority(1)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
//                    } else {
//                        let message: LocalizedStringKey? = viewModel.errorMessage
//                        ValidationMessageText(textKey: message, size: 12, isValid: false)
//                            .layoutPriority(1)
//                            .frame(height: 24)
//                    }
                }
            }, footer: {
                let primaryButtonWidth = width*0.46
                PrimaryButton(
                    action: {
                        viewModel.verifyOTP()
                    },
                    label: {
                        Text(.sdkAsset("continue"))
                    },
                    isDisabled: !viewModel.isVerifyEnable
                )
                .frame(width: primaryButtonWidth, height: primaryButtonWidth*0.35)
            }
        )
    }
    
    @ViewBuilder
    private var resendOTPView: some View {
        if !viewModel.isOTPRequestManyTime && !viewModel.isNotAccountExisted {
            if viewModel.resendCountdown > 0 {
                HStack(spacing: 0) {
                    Spacer()
                    Text(.sdkAsset("resend_in_x_seconds"))
                        .font(AppFont.poppinsRegular.of(size: 12))
                    Text(" \(viewModel.resendCountdown)")
                        .font(AppFont.poppinsBold.of(size: 12))
                        .animation(.easeInOut, value: viewModel.resendCountdown)
                    Text(.sdkAsset("seconds"))
                        .font(AppFont.poppinsBold.of(size: 12))
                    Spacer()
                }
                .foregroundColor(.secondaryText)

            } else {
                UnderlinedButton(
                    title: .sdkAsset("resend_otp"),
                    action: viewModel.requestOTP,
                    textColor: Color(sdkAsset: "TextSecondaryColor"),
                    underlineColor: Color(sdkAsset: "TextSecondaryColor")
                )
            }
        }
    }
    
    @ViewBuilder
    private var otpExpiredView: some View {
        VStack {
            ValidationMessageText(textKey: .sdkAsset("otp_expired"), size: 12, isValid: false)
            UnderlinedButton(
                title: .sdkAsset("resend_otp"),
                action: viewModel.requestOTP,
                textColor: Color(sdkAsset: "TextSecondaryColor"),
                underlineColor: Color(sdkAsset: "TextSecondaryColor")
            )
        }
    }
}

#Preview {
    OTPInputView(
        flowType: FlowType.register,
        phoneNumber: "0909090909",
        otpSendableResponse: .init(otpSent: true, retryAfterSeconds: 60, expiresInSeconds: 300),
        presentedScreen: .constant(nil),
        authManager: DefaultAuthManager.Builder().build(),
        onSuccess: { phoneNumber, otpToken in
            
        },
        onFailure: { authErrorResponse in
            
        }
    )
}

@available(iOS 17.0, *)
#Preview("LandscapeLeft",traits: .landscapeLeft) {
    OTPInputView(
        flowType: FlowType.register,
        phoneNumber: "0909090909",
        otpSendableResponse: .init(otpSent: true, retryAfterSeconds: 60, expiresInSeconds: 300),
        presentedScreen: .constant(nil),
        authManager: DefaultAuthManager.Builder().build(),
        onSuccess: { phoneNumber, otpToken in
            
        },
        onFailure: { authErrorResponse in
            
        }
    )
}
