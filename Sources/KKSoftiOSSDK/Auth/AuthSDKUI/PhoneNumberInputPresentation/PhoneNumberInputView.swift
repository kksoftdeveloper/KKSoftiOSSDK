//
//  SignUpView.swift
//  AuthSDK
//

import SwiftUI

struct PhoneNumberInputView: View {
    @StateObject var viewModel: PhoneNumberInputViewModel
    
    @FocusState private var phoneFocused: Bool
    @SwiftUI.Environment(\.verticalSizeClass) private var verticalSizeClass
    
    init(
        flowType: FlowType,
        presentedScreen: Binding<PopupScreen?>,
        authManager: AuthManager,
        onOTPRequested: ((String, OTPSendableResponse, Bool) -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: PhoneNumberInputViewModel(
            flowType: flowType,
            presentedScreen: presentedScreen,
            authManager: authManager,
            onOTPRequested: onOTPRequested
        ))
    }
    
    var attributedText: AttributedString {
            var str = AttributedString("Tôi xác nhận mình từ đủ 16 tuổi trở lên và đồng ý với ")
            
            // "điều khoản" link
            var dk = AttributedString("Điều khoản sử dụng")
            dk.foregroundColor = .blue
            dk.underlineStyle = .single
            dk.link = URL(string: "https://docs.google.com/document/d/14-sD0kAL9XRNSTjuFu3Oa86xSJw-TSB-z0QaGy7e6OM/edit?tab=t.0")
            str.append(dk)
            
            return str
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
        }
        .onAppear {
            // Wait until the popup’s show animation completed so the field can become first responder.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                phoneFocused = true
            }
        }
    }
    
    
    
    @ViewBuilder
    private func content(width: CGFloat, height: CGFloat) -> some View
    {
        
        AuthContainer(
            wid: width,
            hei: height,
            onCloseClick: {
            viewModel.presentedScreen = nil
        }) {
            VStack {
                Group {
                    Text(.sdkAsset("step_x_of_y", 1, viewModel.registrationStepCount))
                }
                .font(AppFont.fsClanNarrowUltra.of(size: 14))
                .foregroundColor(.secondaryText)
                .padding(.vertical, 5)
                
                Text(FlowType.register.title)
                    .font(AppFont.fsClanNarrowUltra.of(size: 16))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                
                Text(viewModel.flowType.subtitleText)
                    .font(AppFont.poppinsRegular.of(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primaryText)
                    .padding(.bottom, 12)
                
                VStack (alignment: .leading ,spacing: 4) {
                    Text(.sdkAsset("phone_number"))
                        .font(AppFont.poppinsRegular.of(size: 12))
                        .foregroundColor(.secondaryText)
                    PhoneNumberInputText(phoneNumber: $viewModel.phoneNumber)
                        .focused($phoneFocused)
                        .onChange(of: viewModel.phoneNumber) { newValue in
                            viewModel.phoneNumber = newValue.trimmedVietnamPhoneNumber()
                        }
                }
                .padding(.horizontal, 16)
                if viewModel.requiresTermsAcceptance {
                    CheckedBoxText(
                        lineLimit: 2,
                        isChecked: $viewModel.isAcceptedTerm,
                        text: "",
                        onToggle: { newValue in
                            viewModel.isAcceptedTerm = newValue
                        }
                    )
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                if viewModel.flowType == .register {
                    CheckedBoxText(
                        lineLimit: 2,
                        isChecked: $viewModel.isAtLeast16Confirmed,
                        text: "",
                        attributedText: attributedText,
                        onToggle: { newValue in
                            viewModel.isAtLeast16Confirmed = newValue
                        }
                    )
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 8, trailing: 20))
                    
//                    SimpleCheckBoxText(
//                        isChecked: $viewModel.isAtLeast16Confirmed,
//                        text: "I confirm that I am at least 16 years old."
//                    )
//                    .padding(.bottom, 8)
//                    .padding(.horizontal, 16)
                }
                MeasuredBox {
                    let message: LocalizedStringKey? = viewModel.errorMessage
                    ValidationMessageText(textKey: message, size: 12, isValid: false)
                        .layoutPriority(1)
                }
                .padding(.top, 8)
                .padding(.horizontal, 0)
            }
            .padding(.horizontal, 16)
        } footer: {
            let primaryButtonWidth = width*0.46
            PrimaryButton(
                action: {
                    viewModel.requestOTP()
                },
                label: {
                    Text(viewModel.flowType.buttonText)
                },
                isDisabled: !viewModel.isPrimaryButtonEnabled
            )
            .frame(width: primaryButtonWidth, height: primaryButtonWidth*0.35)
        }
        .hideKeyboardOnTap()
    }
}

private struct SimpleCheckBoxText: View {
    @Binding var isChecked: Bool
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Button {
                isChecked.toggle()
            } label: {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 12, height: 12)
                    .foregroundColor(isChecked ? .blue : .brownish)
            }
            Text(text)
                .font(AppFont.poppinsLight.of(size: 10))
                .foregroundColor(.grayish)
            Spacer()
        }
    }
}

private extension FlowType {
    var title: String {
        switch self {
        case .register, .forgetPassword, .linkToNewAccount:
            return LocalizedStringKey.sdkAsset("input_your_phone_number").toString().uppercased()
        }
    }
    
    var subtitleText: String {
        switch self {
        case .register, .forgetPassword, .linkToNewAccount:
            return LocalizedStringKey.sdkAsset("we_will_send_you_verify_code").toString()
        }
    }
    
    var buttonText: String {
        switch self {
        case .register, .linkToNewAccount, .forgetPassword:
            return LocalizedStringKey.sdkAsset("receive_otp").toString()
        }
    }
}

#Preview {
    PhoneNumberInputView(flowType: .register, presentedScreen: .constant(nil), authManager: DefaultAuthManager.Builder().build())
}
