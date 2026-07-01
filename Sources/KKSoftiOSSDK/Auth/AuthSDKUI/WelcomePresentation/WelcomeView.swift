//
//  WelcomeView.swift
//  AuthSDK
//

import SwiftUI
import AuthenticationServices
import UIKit
import AppTrackingTransparency


public struct WelcomeView: View {
    
//    @State private var showKeyboardToolbar = false
    
    @StateObject private var viewModel: WelcomeViewModel
    @FocusState private var focusedField: WelcomeViewModel.FocusField?
    
    @SwiftUI.Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private let packageName: String
    private let appVersionName: String
    private let serverId: Int
    private let onClose: () -> Void
    private let onSuccess: (AuthSessionResponse) -> Void
    private let onRefreshedToken: (AuthSessionResponse) -> Void
    private let onFailure: (AuthErrorResponse) -> Void
    
    @State private var tapCount = 0
    @State private var showToast = false
    @State private var showIDFVDialog = false
    @State private var hasRequestedTrackingAuthorization = false
    @State private var completedRegistrationSession: AuthSessionResponse?
    
    public init(authManager: AuthManager,
                packageName: String,
                appVersionName: String,
                serverId: Int,
                onSuccess: @escaping (AuthSessionResponse) -> Void,
                onRefreshedToken: @escaping (AuthSessionResponse) -> Void,
                onFailure: @escaping (AuthErrorResponse) -> Void,
                onClose: @escaping () -> Void
    ) {
        
        self.packageName = packageName
        self.appVersionName = appVersionName
        self.serverId = serverId
        self.onClose = onClose
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.onRefreshedToken = onRefreshedToken
        
        self._viewModel = StateObject(
            wrappedValue: WelcomeViewModel(authManager: authManager,
                                           onLoginSuccess: onSuccess,
                                           onLoginFailure: onFailure,
                                           onClose: onClose))
    }
    
    public var body: some View {
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
            .onAppear {
                AuthTracking.logOpenLoginForm()
                requestTrackingAuthorizationIfNeeded()
                viewModel.initSDK(
                    packageName: packageName,
                    appVersionName: appVersionName,
                    serverId: serverId)
            }
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name(DefaultAuthManager.REFERSH_TOKEN_KEY))) { notification in
                if let authResponse = notification.object as? AuthSessionResponse {
                    debugPrint("Received AuthSessionResponse: \(authResponse)")
                    onRefreshedToken(authResponse)
                }
            }
//            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name(DefaultAuthManager.UNAUTHENTICATED_TOKEN_KEY))) { notification in
//                
//            }
//            .toast(message: Binding<String?>(
//                get: { viewModel.errorMessage },
//                set: { viewModel.errorMessage = $0 }
//            ))
        }
    }
    
    @ViewBuilder
    public func content(width: CGFloat, height: CGFloat) -> some View {
        let isPortrait = verticalSizeClass == .regular
        AuthContainer(
            wid: width,
            hei: height,
            shouldShowCross: false,
            // shouldShowLogo: false,
            onCloseClick: {
                onClose()
            },
            onLogoTaps: {
                tapCount += 1
                if tapCount == 7 {
                    showIDFVDialog = true
                    tapCount = 0
                }
                debugPrint("on-logo-taps: \(tapCount)")
            }
        ) {
                VStack(spacing: isPortrait ? 10 : 6) {
                    Text(.sdkAsset("login"))
                        .font(AppFont.fsClanNarrowUltra.of(size: 22))
                        .foregroundColor(.primaryText)
                        .padding(.top, isPortrait ? 16 : 0)
                        .padding(.bottom, isPortrait ? 2 : 0)
                    
                    // Bindings for formState
                    let phoneBinding = Binding(
                        get: { viewModel.formState.phoneNumber },
                        set: { viewModel.formState.phoneNumber = $0 }
                    )
                    let passBinding = Binding(
                        get: { viewModel.formState.password },
                        set: { viewModel.formState.password = $0 }
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        requiredFieldLabel(.sdkAsset("phone_number"))
                        
                        PhoneNumberInputText(
                            phoneNumber: phoneBinding,
                            onSubmit: {
                                viewModel.handleSubmit(from: .phone)
                            },
                            placeholder: "+(84)",
                            height: 40
                        )
                        .onSubmit {
                            focusedField = .password
                        }
                        .onChange(of: viewModel.formState.phoneNumber) { newValue in
                            viewModel.formState.phoneNumber = newValue.trimmedVietnamPhoneNumber()
                        }
                        .focused($focusedField, equals: .phone)
                        .submitLabel(.next)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        requiredFieldLabel(.sdkAsset("password"))
                        
                        SecureInputView("6–20 kí tự", text: passBinding, height: 40)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = nil
                                viewModel.handleSubmit(from: .password)
                            }
                    }
                    .padding(.top, 4)
                    
                    loginTextButton(title: .sdkAsset("forgot_password")) {
                        focusedField = nil
                        viewModel.presentedScreen = .register(type: .forgetPassword)
                    }.padding(.top, isPortrait ? 4 : 3)
                    
                    CheckedBoxText(
                        lineLimit: 2,
                        isChecked: Binding(
                            get: { viewModel.formState.isAcceptedTerm },
                            set: { viewModel.formState.isAcceptedTerm = $0 }
                        ),
                        text: "",
                        highlight: viewModel.shouldHighlightTerms,
                        attributedText: loginTermsText,
                        onToggle: {
                            viewModel.formState.isAcceptedTerm = $0
                        }
                    )
                    .padding(.top, isPortrait ? 2 : 0)
                    
                    HStack(spacing: 12) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.5))
                        Text(.sdkAsset("or_continue_with"))
                            .font(AppFont.poppinsRegular.of(size: 11))
                            .foregroundColor(.black.opacity(0.75))
                            .layoutPriority(1)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.5))
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, isPortrait ? 8 : 3)

                    let iconSize = isPortrait ? 15.0 : 10.0
                    HStack(spacing: 12) {
                        socialLoginButton(
                            iconName: "IconApple",
                            title: "Apple",
                            iconSize: iconSize,
                            action: {
                                focusedField = nil
                                viewModel.loginViaApple()
                            }
                        )
                        
                        socialLoginButton(
                            iconName: "IconGoogle",
                            title: "Google",
                            iconSize: iconSize,
                            action: {
                                focusedField = nil
                                viewModel.loginGoogle()
                            }
                        )
                        
                        socialLoginButton(
                            iconName: "IconFacebook",
                            title: "Facebook",
                            iconSize: iconSize,
                            action: {
                                focusedField = nil
                                viewModel.loginFacebook()
                            }
                        )
                    }
                    .padding(.top, isPortrait ? 4 : 2)
                    
                    HStack {
                        Text(.sdkAsset("donot_have_an_account"))
                            .foregroundColor(.sdkSecondaryText)
                            .font(AppFont.poppinsRegular.of(size: 10))
                        
                        loginTextButton(title: .sdkAsset("sign_up_now")) {
                                focusedField = nil
                                viewModel.presentedScreen = .register(type: .register)
                        }
                    }
                    .padding(.top, isPortrait ? 4 : 2)

                    if viewModel.isLoading == false && viewModel.errorMessage != nil {
                        ErrorMessageView(
                            textKey: viewModel.errorMessage!
                        )
                    }
                }
                .padding(.horizontal, 12)
//                .toolbar {
//                    ToolbarItemGroup(placement: .keyboard) {
//                        if focusedField != nil {
//                            Spacer()
//                            if focusedField == .password {
//                                Button("Previous") {
//                                    focusedField = .phone
//                                }
//                            } else {
//                                Button("Next") {
//                                    switch focusedField {
//                                    case .phone:
//                                        focusedField = .password
//                                    default:
//                                        viewModel.login()
//                                        focusedField = nil
//                                    }
//                                }
//                            }
//                            Button("Done") {
//                                viewModel.login()
//                                focusedField = nil
//                            }
//                        }
//                        
//                    }
//                }
            } footer: {
                let primaryButtonWidth = width*0.46
                PrimaryButton(
                    action: {
                        viewModel.login()
                    },
                    label: {
                        Text(.sdkAsset("login"))
                    },
                    isDisabled: !viewModel.formState.isLoginEnabled // !viewModel.isLoginEnabled
                )
                .frame(width: primaryButtonWidth, height: primaryButtonWidth*0.35)
            }
            .hideKeyboardOnTap()
        if showIDFVDialog {
            IDFVDialogView(
                idfv: UIDevice.current.identifierForVendor?.uuidString ?? "Not Available",
                onDismiss: {
                    showIDFVDialog = false
                }
                
            )
        }
    }
    
    private var loginTermsText: AttributedString {
        var text = AttributedString("Tôi đồng ý với ")
        text.foregroundColor = .grayish

        var terms = AttributedString("Điều khoản")
        terms.foregroundColor = .blue
        terms.link = URL(string: "https://kksoft.vn/dieu-khoan")
        text.append(terms)

        var andText = AttributedString(" và ")
        andText.foregroundColor = .grayish
        text.append(andText)

        var policy = AttributedString("Chính sách sử dụng")
        policy.foregroundColor = .blue
        policy.link = URL(string: "https://kksoft.vn/chinh-sach-su-dung")
        text.append(policy)

        return text
    }

    @ViewBuilder
    private func requiredFieldLabel(_ title: LocalizedStringKey) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(AppFont.poppinsRegular.of(size: 13))
                .foregroundColor(.primaryText)
            Text("*")
                .font(AppFont.poppinsRegular.of(size: 13))
                .foregroundColor(.red)
        }
    }

    private func socialLoginButton(
        iconName: String,
        title: String,
        iconSize: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        SecondaryButton(
            action: action,
            content: {
                HStack(spacing: 5) {
                    Image(sdkAsset: iconName)
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: iconSize, height: iconSize)

                    Text(title)
                        .font(AppFont.poppinsMedium.of(size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 20)
            }
        )
        .frame(height: 36)
        .layoutPriority(1)
    }

    private func loginTextButton(
        title: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.poppinsBold.of(size: 13))
                .foregroundColor(.blue)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .buttonStyle(.plain)
    }

    private func requestTrackingAuthorizationIfNeeded() {
        guard !hasRequestedTrackingAuthorization else { return }
        hasRequestedTrackingAuthorization = true
        guard #available(iOS 14, *) else { return }
        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else { return }
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                debugPrint("✅ ATT: Tracking authorized")
            case .denied:
                debugPrint("❌ ATT: Tracking denied")
            case .restricted:
                debugPrint("❌ ATT: Tracking restricted")
            case .notDetermined:
                debugPrint("❌ ATT: Tracking not determined")
            @unknown default:
                debugPrint("❌ ATT: Unknown tracking status \(status.rawValue)")
            }
        }
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
            
        case .otpInput(let flowType, let phoneNumber, let otpSendableResponse, let isAtLeast16Confirmed):
            OTPInputView(
                flowType: flowType,
                phoneNumber: phoneNumber,
                otpSendableResponse: otpSendableResponse,
                stepIndex: 2,
                totalStepCount: flowType == .register ? (isAtLeast16Confirmed ? 4 : 6) : 3,
                presentedScreen: $viewModel.presentedScreen,
                authManager: viewModel.authManager,
                onSuccess: { phoneNumber, otpToken in
                    if flowType == .register {
                        viewModel.presentedScreen = .personalInformation(
                            phoneNumber: phoneNumber,
                            otpVerifiedToken: otpToken,
                            isAtLeast16Confirmed: isAtLeast16Confirmed
                        )
                    } else {
                        viewModel.presentedScreen = .passwordInput(
                            type: flowType,
                            phoneNumber: phoneNumber,
                            otpVerifiedToken: otpToken,
                            accountInformation: nil
                        )
                    }
                },
                onFailure: { authError in
                    debugPrint("OTP verification failed with message \(authError)")
                }
            )
        case .personalInformation(let phoneNumber, let otpVerifiedToken, let isAtLeast16Confirmed):
            UpdateAccountInformation(
                authManager: viewModel.authManager,
                phoneNumber: phoneNumber,
                isAtLeast16Confirmed: isAtLeast16Confirmed,
                screenStep: .personal,
                onClose: {
                    viewModel.presentedScreen = nil
                },
                onPersonalInfoReady: { accountInformation in
                    viewModel.presentedScreen = .guardianInformation(
                        phoneNumber: phoneNumber,
                        otpVerifiedToken: otpVerifiedToken,
                        isAtLeast16Confirmed: isAtLeast16Confirmed,
                        accountInformation: accountInformation
                    )
                },
                onRegistrationInfoReady: { accountInformation, _ in
                    viewModel.presentedScreen = .passwordInput(
                        type: .register,
                        phoneNumber: phoneNumber,
                        otpVerifiedToken: otpVerifiedToken,
                        accountInformation: accountInformation
                    )
                }
            )
        case .guardianInformation(let phoneNumber, let otpVerifiedToken, let isAtLeast16Confirmed, let baseAccountInformation):
            UpdateAccountInformation(
                authManager: viewModel.authManager,
                phoneNumber: phoneNumber,
                isAtLeast16Confirmed: isAtLeast16Confirmed,
                screenStep: .guardian,
                baseAccountInformation: baseAccountInformation,
                onClose: {
                    viewModel.presentedScreen = nil
                },
                onRegistrationInfoReady: { accountInformation, guardianOTPResponse in
                    guard let guardianOTPResponse else { return }
                    viewModel.presentedScreen = .guardianOTPInput(
                        phoneNumber: phoneNumber,
                        otpVerifiedToken: otpVerifiedToken,
                        guardianPhoneNumber: accountInformation.guardianInfo.phoneNumber,
                        otpSendableResponse: guardianOTPResponse,
                        accountInformation: accountInformation
                    )
                }
            )
        case .guardianOTPInput(let phoneNumber, let otpVerifiedToken, let guardianPhoneNumber, let otpSendableResponse, let accountInformation):
            OTPInputView(
                flowType: .register,
                phoneNumber: guardianPhoneNumber,
                otpSendableResponse: otpSendableResponse,
                stepIndex: 5,
                totalStepCount: 6,
                presentedScreen: $viewModel.presentedScreen,
                authManager: viewModel.authManager,
                onSuccess: { _, guardianOTPToken in
                    let verifiedGuardianInfo = GuardianInfo(
                        fullName: accountInformation.guardianInfo.fullName,
                        gender: accountInformation.guardianInfo.gender,
                        dob: accountInformation.guardianInfo.dob,
                        address: accountInformation.guardianInfo.address,
                        idNumber: accountInformation.guardianInfo.idNumber,
                        idIssueDate: accountInformation.guardianInfo.idIssueDate,
                        idIssuePlace: accountInformation.guardianInfo.idIssuePlace,
                        relation: accountInformation.guardianInfo.relation,
                        locked: accountInformation.guardianInfo.locked,
                        phoneNumber: accountInformation.guardianInfo.phoneNumber,
                        otpVerifiedToken: guardianOTPToken
                    )
                    let verifiedAccountInformation = AccountInformation(
                        avatarUrl: accountInformation.avatarUrl,
                        displayName: accountInformation.displayName,
                        personalInfo: accountInformation.personalInfo,
                        guardianInfo: verifiedGuardianInfo,
                        sign: accountInformation.sign
                    )
                    viewModel.presentedScreen = .passwordInput(
                        type: .register,
                        phoneNumber: phoneNumber,
                        otpVerifiedToken: otpVerifiedToken,
                        accountInformation: verifiedAccountInformation
                    )
                },
                onFailure: { authError in
                    debugPrint("Guardian OTP verification failed with message \(authError)")
                }
            )
        case .accountInfoConfirmation:
            AccountInfoConfirmationView(
                onClose: {
                    viewModel.presentedScreen = nil
                },
                onContinue: { isAtLeast16Confirmed in
                    viewModel.startProfileCompletion(isAtLeast16Confirmed: isAtLeast16Confirmed)
                }
            )
        case .postLoginPhoneNumberInput(let session, let isAtLeast16Confirmed):
            PhoneNumberInputView(
                flowType: .register,
                presentedScreen: $viewModel.presentedScreen,
                authManager: viewModel.authManager,
                onOTPRequested: { phoneNumber, otpResponse, isAtLeast16Confirmed in
                    viewModel.presentedScreen = .postLoginPhoneOTPInput(
                        session: session,
                        phoneNumber: phoneNumber,
                        otpSendableResponse: otpResponse,
                        isAtLeast16Confirmed: isAtLeast16Confirmed
                    )
                }
            )
        case .postLoginPhoneOTPInput(let session, let phoneNumber, let otpSendableResponse, let isAtLeast16Confirmed):
            OTPInputView(
                flowType: .register,
                phoneNumber: phoneNumber,
                otpSendableResponse: otpSendableResponse,
                stepIndex: 2,
                totalStepCount: isAtLeast16Confirmed ? 3 : 5,
                presentedScreen: $viewModel.presentedScreen,
                authManager: viewModel.authManager,
                onSuccess: { phoneNumber, _ in
                    viewModel.presentedScreen = .postLoginPersonalInformation(
                        session: session,
                        phoneNumber: phoneNumber,
                        isAtLeast16Confirmed: isAtLeast16Confirmed
                    )
                },
                onFailure: { authError in
                    debugPrint("Post-login phone OTP verification failed with message \(authError)")
                }
            )
        case .postLoginPersonalInformation(let session, let phoneNumber, let isAtLeast16Confirmed):
            UpdateAccountInformation(
                authManager: viewModel.authManager,
                phoneNumber: phoneNumber,
                isAtLeast16Confirmed: isAtLeast16Confirmed,
                screenStep: .personal,
                onClose: {
                    viewModel.presentedScreen = nil
                },
                onPersonalInfoReady: { accountInformation in
                    viewModel.presentedScreen = .postLoginGuardianInformation(
                        session: session,
                        isAtLeast16Confirmed: isAtLeast16Confirmed,
                        accountInformation: accountInformation
                    )
                },
                onRegistrationInfoReady: { accountInformation, _ in
                    viewModel.finishProfileCompletion()
                }
            )
        case .postLoginGuardianInformation(let session, let isAtLeast16Confirmed, let baseAccountInformation):
            UpdateAccountInformation(
                authManager: viewModel.authManager,
                phoneNumber: baseAccountInformation.personalInfo.phoneNumber,
                isAtLeast16Confirmed: isAtLeast16Confirmed,
                screenStep: .guardian,
                baseAccountInformation: baseAccountInformation,
                onClose: {
                    viewModel.presentedScreen = nil
                },
                onRegistrationInfoReady: { accountInformation, guardianOTPResponse in
                    guard let guardianOTPResponse else { return }
                    viewModel.presentedScreen = .postLoginGuardianOTPInput(
                        session: session,
                        guardianPhoneNumber: accountInformation.guardianInfo.phoneNumber,
                        otpSendableResponse: guardianOTPResponse,
                        accountInformation: accountInformation
                    )
                }
            )
        case .postLoginGuardianOTPInput(_, let guardianPhoneNumber, let otpSendableResponse, let accountInformation):
            OTPInputView(
                flowType: .register,
                phoneNumber: guardianPhoneNumber,
                otpSendableResponse: otpSendableResponse,
                stepIndex: 5,
                totalStepCount: 5,
                presentedScreen: $viewModel.presentedScreen,
                authManager: viewModel.authManager,
                onSuccess: { _, _ in
                    viewModel.finishProfileCompletion()
                },
                onFailure: { authError in
                    debugPrint("Post-login guardian OTP verification failed with message \(authError)")
                }
            )
        case .passwordInput(let flowType, let phoneNumber, let otpVerifiedToken, let accountInformation):
            PasswordInputView(
                flowType: flowType,
                phoneNumber: phoneNumber,
                otpVerifiedToken: otpVerifiedToken,
                accountInformation: accountInformation,
                stepIndex: flowType == .register ? (accountInformation?.guardianInfo.phoneNumber.isEmpty == false ? 6 : 4) : 3,
                totalStepCount: flowType == .register ? (accountInformation?.guardianInfo.phoneNumber.isEmpty == false ? 6 : 4) : 3,
                presentedScreen: $viewModel.presentedScreen,
                authManager: viewModel.authManager,
                onSuccess: { flowType, session in
                    debugPrint("set up password success \(flowType) \(session)")
                    if flowType == .register {
                        if let session = session {
                            completedRegistrationSession = session
                            viewModel.presentedScreen = .registrationCompleted
                        }
                    }
                },
                onFailure: { authErrorResponse in
                    debugPrint("set up password failure \(authErrorResponse)")
                    DispatchQueue.main.async {
                        self.onFailure(authErrorResponse)
                    }
                }
            )
        case .updateAccountInfo:
            UpdateAccountInformation(
                authManager: viewModel.authManager,
                onClose: {
                    viewModel.presentedScreen = nil
                },
                onSuccess: { isSuccess in
                    guard isSuccess else { return }
                    if let session = viewModel.authSession {
                        self.onSuccess(session)
                    } else {
                        viewModel.presentedScreen = nil
                    }
                }
            )
        case .registrationCompleted:
            RegistrationCompletedView {
                if let session = completedRegistrationSession {
                    self.onSuccess(session)
                } else {
                    viewModel.presentedScreen = nil
                }
            }
        case .userBlocked:
            UserBlockedView(phoneNumber: "+84398686854",
                            fanpage: "https://www.facebook.com/profile.php?id=61574162151534",
                            onClose: {
                viewModel.presentedScreen = nil
            })
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

public enum PopupScreen: Hashable, Identifiable, Equatable {
    case register(type: FlowType)
    case otpInput(type: FlowType, phoneNumber: String, otpSendableResponse: OTPSendableResponse, isAtLeast16Confirmed: Bool)
    case personalInformation(phoneNumber: String, otpVerifiedToken: String, isAtLeast16Confirmed: Bool)
    case guardianInformation(phoneNumber: String, otpVerifiedToken: String, isAtLeast16Confirmed: Bool, accountInformation: AccountInformation)
    case guardianOTPInput(phoneNumber: String, otpVerifiedToken: String, guardianPhoneNumber: String, otpSendableResponse: OTPSendableResponse, accountInformation: AccountInformation)
    case passwordInput(type: FlowType, phoneNumber: String, otpVerifiedToken: String, accountInformation: AccountInformation?)
    case accountInfoConfirmation(session: AuthSessionResponse)
    case postLoginPhoneNumberInput(session: AuthSessionResponse, isAtLeast16Confirmed: Bool)
    case postLoginPhoneOTPInput(session: AuthSessionResponse, phoneNumber: String, otpSendableResponse: OTPSendableResponse, isAtLeast16Confirmed: Bool)
    case postLoginPersonalInformation(session: AuthSessionResponse, phoneNumber: String, isAtLeast16Confirmed: Bool)
    case postLoginGuardianInformation(session: AuthSessionResponse, isAtLeast16Confirmed: Bool, accountInformation: AccountInformation)
    case postLoginGuardianOTPInput(session: AuthSessionResponse, guardianPhoneNumber: String, otpSendableResponse: OTPSendableResponse, accountInformation: AccountInformation)
    case linkAccount(guestToken: String)
    case updateAccountInfo
    case forceUpdate
    case wellcome
    case logoutConfirm
    case packageList
    case sdk
    case gameServer
    case deleteAccount
    case registrationCompleted
    case userBlocked
    
    public var id: String {
        switch self {
        case .register(let type):
            return "register-\(type)"
        case .otpInput(_, let phoneNumber, _, let isAtLeast16Confirmed):
            return "otp-\(phoneNumber)-\(isAtLeast16Confirmed)"
        case .personalInformation(let phoneNumber, _, let isAtLeast16Confirmed):
            return "personal-info-\(phoneNumber)-\(isAtLeast16Confirmed)"
        case .guardianInformation(let phoneNumber, _, let isAtLeast16Confirmed, _):
            return "guardian-info-\(phoneNumber)-\(isAtLeast16Confirmed)"
        case .guardianOTPInput(let phoneNumber, _, let guardianPhoneNumber, _, _):
            return "guardian-otp-\(phoneNumber)-\(guardianPhoneNumber)"
        case .passwordInput(_, let phoneNumber, _, _):
            return "password-\(phoneNumber)"
        case .accountInfoConfirmation(let session):
            return "account-info-confirmation-\(session.accessToken)"
        case .postLoginPhoneNumberInput(let session, let isAtLeast16Confirmed):
            return "post-login-phone-\(session.accessToken)-\(isAtLeast16Confirmed)"
        case .postLoginPhoneOTPInput(let session, let phoneNumber, _, let isAtLeast16Confirmed):
            return "post-login-phone-otp-\(session.accessToken)-\(phoneNumber)-\(isAtLeast16Confirmed)"
        case .postLoginPersonalInformation(let session, let phoneNumber, let isAtLeast16Confirmed):
            return "post-login-personal-\(session.accessToken)-\(phoneNumber)-\(isAtLeast16Confirmed)"
        case .postLoginGuardianInformation(let session, let isAtLeast16Confirmed, _):
            return "post-login-guardian-\(session.accessToken)-\(isAtLeast16Confirmed)"
        case .postLoginGuardianOTPInput(let session, let guardianPhoneNumber, _, _):
            return "post-login-guardian-otp-\(session.accessToken)-\(guardianPhoneNumber)"
        case .linkAccount(let guestToken):
            return "link-\(guestToken)"
        case .updateAccountInfo:
            return "update-account-info"
        case .forceUpdate:
            return "force-update"
        case .wellcome:
            return "wellcome"
        case .logoutConfirm:
            return "logout-confirm"
        case .packageList:
            return "package-list"
        case .sdk:
            return "sdk"
        case .gameServer:
            return "game-server"
        case .deleteAccount:
            return "delete-account"
        case .registrationCompleted:
            return "registration-completed"
        case .userBlocked:
            return "user-blocked"
        }
    }
}

public enum FlowType {
    case register
    case forgetPassword
    case linkToNewAccount
}

extension Date {
    func toString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
}

private struct RegistrationCompletedView: View {
    @SwiftUI.Environment(\.verticalSizeClass) private var verticalSizeClass
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geo in
            let isLandscape = verticalSizeClass == .compact
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let width = UIScreen.main.bounds.size.width
            let height = UIScreen.main.bounds.size.height
            let minValue = min(width, height, CGFloat((isPad ? 440 : Int.max)))
            let contentWidth = isLandscape ? minValue * 0.8 * 0.9 : minValue
            let contentHeight = isLandscape ? minValue * 0.9 : minValue * 1.2

            AuthContainer(
                wid: contentWidth,
                hei: contentHeight,
                shouldShowCross: false,
                onCloseClick: {},
                content: {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundColor(.green)

                        Text("Registration Completed")
                            .font(AppFont.fsClanNarrowUltra.of(size: 18))
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, isLandscape ? 24 : 68)
                },
                footer: {
                    let primaryButtonWidth = contentWidth * 0.46
                    PrimaryButton(
                        action: onContinue,
                        label: {
                            Text(.sdkAsset("continue"))
                        },
                        isDisabled: false
                    )
                    .frame(width: primaryButtonWidth, height: primaryButtonWidth * 0.35)
                }
            )
            .preferredColorScheme(.light)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .background(Color.black.opacity(0.5))
        }
    }
}

private struct AccountInfoConfirmationView: View {
    @SwiftUI.Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isAtLeast16Confirmed = true

    let onClose: () -> Void
    let onContinue: (Bool) -> Void

    private var confirmationText: AttributedString {
        AttributedString("Tôi xác nhận mình từ đủ 16 tuổi trở lên")
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = verticalSizeClass == .compact
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            let width = UIScreen.main.bounds.size.width
            let height = UIScreen.main.bounds.size.height
            let minValue = min(width, height, CGFloat((isPad ? 440 : Int.max)))
            let contentWidth = isLandscape ? minValue * 0.8 * 0.9 : minValue
            let contentHeight = isLandscape ? minValue * 0.9 : minValue * 1.2

            AuthContainer(
                wid: contentWidth,
                hei: contentHeight,
                onCloseClick: onClose,
                content: {
                    VStack(spacing: 14) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundColor(.orange)

                        Text("Cần cập nhật thông tin")
                            .font(AppFont.fsClanNarrowUltra.of(size: 18))
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.center)

                        Text("Vui lòng bổ sung thông tin bắt buộc để tiếp tục đăng nhập.")
                            .font(AppFont.poppinsRegular.of(size: 12))
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, isLandscape ? 24 : 48)

                        CheckedBoxText(
                            lineLimit: 2,
                            isChecked: $isAtLeast16Confirmed,
                            text: "",
                            attributedText: confirmationText,
                            onToggle: { newValue in
                                isAtLeast16Confirmed = newValue
                            }
                        )
                        .padding(.horizontal, isLandscape ? 24 : 48)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                },
                footer: {
                    let primaryButtonWidth = contentWidth * 0.46
                    PrimaryButton(
                        action: {
                            onContinue(isAtLeast16Confirmed)
                        },
                        label: {
                            Text(.sdkAsset("continue"))
                        },
                        isDisabled: false
                    )
                    .frame(width: primaryButtonWidth, height: primaryButtonWidth * 0.35)
                }
            )
            .preferredColorScheme(.light)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .background(Color.black.opacity(0.5))
        }
    }
}

// MARK: - IDFV Dialog View
struct IDFVDialogView: View {
    let idfv: String
    let onDismiss: () -> Void
    
    @State private var appsFlyerCopied = false
    @State private var adjustCopied = false
    @State private var adjustAdId: String? = nil
    @State private var isLoadingAdjustId = true
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 4) {
                        HStack {
                            Text("Tracking IDs")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Button(action: {
                                onDismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Release Date
                        HStack {
                            Text("@2025-10-17")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // AppsFlyer IDFV Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AppsFlyer IDFV")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        Text(idfv)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        // Copy Button
                        Button(action: {
                            UIPasteboard.general.string = idfv
                            appsFlyerCopied = true
                            debugPrint("✅ AppsFlyer IDFV copied to clipboard: \(idfv)")
                            
                            // Reset copied state after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                appsFlyerCopied = false
                            }
                        }) {
                            HStack {
                                Image(systemName: appsFlyerCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 16))
                                Text(appsFlyerCopied ? "Copied!" : "Copy IDFV")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appsFlyerCopied ? Color.green : Color.blue)
                            .cornerRadius(8)
                        }
                        
                        // Hint text
                        Text("💡 Copy this IDFV and add it to AppsFlyer dashboard for testing")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal)
                    
                    // Adjust Ad ID Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adjust Ad ID")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        if isLoadingAdjustId {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        } else if let adjustId = adjustAdId {
                            Text(adjustId)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            // Copy Button
                            Button(action: {
                                UIPasteboard.general.string = adjustId
                                adjustCopied = true
                                debugPrint("✅ Adjust Ad ID copied to clipboard: \(adjustId)")
                                
                                // Reset copied state after 2 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    adjustCopied = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: adjustCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                        .font(.system(size: 16))
                                    Text(adjustCopied ? "Copied!" : "Copy Ad ID")
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(adjustCopied ? Color.green : Color.blue)
                                .cornerRadius(8)
                            }
                            
                            // Hint text
                            Text("💡 Copy this Ad ID for Adjust dashboard testing")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Not Available")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("💡 Adjust Ad ID will be available after SDK initialization")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
        .onAppear {
            loadAdjustAdId()
        }
    }
    
    private func loadAdjustAdId() {
        // Get TrackingManager from AuthTrackingConfigurator
        if let trackingManager = AuthTrackingConfigurator.currentManager {
            trackingManager.getAdjustId { adid in
                DispatchQueue.main.async {
                    self.adjustAdId = adid
                    self.isLoadingAdjustId = false
                }
            }
        } else {
            // If no tracking manager, mark as not available
            DispatchQueue.main.async {
                self.isLoadingAdjustId = false
            }
        }
    }
}

#Preview {
    WelcomeView(authManager: DefaultAuthManager.Builder().build(),
                packageName: Bundle.main.bundleIdentifier!,
                appVersionName: "1.0.0",
                serverId: 22,
                onSuccess: { AuthSessionResponse in
        
    },
                onRefreshedToken: { AuthSessionResponse in
        
    },
                onFailure: { message in
        
    },
                onClose: { }
    )
}
