//
//  UpdateAccountInformation.swift
//  AuthSDK
//
//  Created by KKSOFT on 5/6/26.
//

import SwiftUI

struct UpdateAccountInformation: View {
    @StateObject var viewModel: UpdateAccountInformationViewModel
    @SwiftUI.Environment(\.verticalSizeClass) var verticalSizeClass

    private let onClose: () -> Void

    init(
        authManager: AuthManager,
        onClose: @escaping () -> Void = {},
        onSuccess: @escaping (Bool) -> Void
    ) {
        self.onClose = onClose
        _viewModel = StateObject(
            wrappedValue: UpdateAccountInformationViewModel(
                authManager: authManager,
                onSuccess: onSuccess
            )
        )
    }

    init(
        authManager: AuthManager,
        phoneNumber: String,
        isAtLeast16Confirmed: Bool,
        screenStep: UpdateAccountInformationViewModel.InfoStep = .personal,
        baseAccountInformation: AccountInformation? = nil,
        onClose: @escaping () -> Void = {},
        onPersonalInfoReady: @escaping (AccountInformation) -> Void = { _ in },
        onRegistrationInfoReady: @escaping (AccountInformation, OTPSendableResponse?) -> Void
    ) {
        self.onClose = onClose
        _viewModel = StateObject(
            wrappedValue: UpdateAccountInformationViewModel(
                authManager: authManager,
                phoneNumber: phoneNumber,
                isAtLeast16Confirmed: isAtLeast16Confirmed,
                screenStep: screenStep,
                baseAccountInformation: baseAccountInformation,
                onPersonalInfoReady: onPersonalInfoReady,
                onRegistrationInfoReady: onRegistrationInfoReady
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
            let contentWidth = isLandscape ? minValue * 0.8 * 0.9 : minValue
            let contentHeight = isLandscape ? minValue * 0.9 : minValue * 1.2

            content(width: contentWidth, height: contentHeight)
                .preferredColorScheme(.light)
                .frame(
                    width: geo.size.width,
                    height: geo.size.height,
                    alignment: .center
                )
                .navigationBarHidden(true)
                .background(Color.black.opacity(0.5))
                .overlay {
                    if viewModel.isLoading {
                        ZStack {
                            Color.clear.ignoresSafeArea()
                            ProgressView(.sdkAsset("loading"))
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                                .background(Color.sdkPrimaryText)
                                .cornerRadius(10)
                                .shadow(radius: 10)
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private func content(width: CGFloat, height: CGFloat) -> some View {
        AuthContainer(
            wid: width,
            hei: height,
            onCloseClick: onClose,
            content: {
                let isLandscape = verticalSizeClass == .compact
                let horizontalPadding: CGFloat = 16
                let scrollHeight = height * (isLandscape ? 0.48 : 0.56)

                VStack(spacing: 6) {
                    Text(.sdkAsset("step_x_of_y", viewModel.stepIndex, viewModel.totalStepCount))
                        .font(AppFont.fsClanNarrowUltra.of(size: 14))
                        .foregroundColor(.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 5)

                    Text(viewModel.screenTitle)
                        .font(AppFont.fsClanNarrowUltra.of(size: 16))
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)

                    ScrollView(showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 8) {
                            if viewModel.screenStep == .personal {
                                personalFields
                            } else {
                                guardianFields
                            }

                            if let errorMessage = viewModel.errorMessage {
                                ValidationMessageText(textKey: errorMessage)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    .frame(height: scrollHeight)
                    .clipped()
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, isLandscape ? 18 : 46)
                .padding(.bottom, isLandscape ? 34 : 48)
            },
            footer: {
                let primaryButtonWidth = width * 0.46
                PrimaryButton(
                    action: {
                        viewModel.submit()
                    },
                    label: {
                        Text(.sdkAsset("confirm"))
                    },
                    isDisabled: !viewModel.isPrimaryButtonEnabled
                )
                .frame(width: primaryButtonWidth, height: primaryButtonWidth * 0.35)
            }
        )
        .hideKeyboardOnTap()
    }

    private var personalFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            formField("Họ tên", text: $viewModel.fullName, placeholder: "Nguyễn Văn A")
            DateInputField(
                title: "Ngày sinh",
                text: $viewModel.dateOfBirth,
                onInputChange: viewModel.updateDateOfBirthInput
            )
            if let dateOfBirthErrorMessage = viewModel.dateOfBirthErrorMessage {
                ValidationMessageText(textKey: dateOfBirthErrorMessage)
            }
            if viewModel.shouldShowPhoneNumber {
                formField("Số điện thoại", text: $viewModel.phoneNumber, placeholder: "(+84) 912 345 678", keyboardType: .phonePad)
            }
            genderPicker("Giới tính", selection: $viewModel.gender)
            formField("Địa chỉ", text: $viewModel.address, placeholder: "123 Abc, Bình Hưng, TP.HCM")

            if viewModel.shouldShowTerms {
                CheckedBoxText(
                    lineLimit: 2,
                    isChecked: $viewModel.isAcceptedTerm,
                    text: "",
                    onToggle: { newValue in
                        viewModel.isAcceptedTerm = newValue
                    }
                )
                .padding(.top, 4)
            }
        }
    }

    private var guardianFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            formField("Họ tên người giám hộ", text: $viewModel.guardianFullName, placeholder: "Nguyễn Văn A")
            DateInputField(
                title: "Ngày sinh người giám hộ",
                text: $viewModel.guardianDateOfBirth,
                onInputChange: viewModel.updateGuardianDateOfBirthInput
            )
            if let guardianDateOfBirthErrorMessage = viewModel.guardianDateOfBirthErrorMessage {
                ValidationMessageText(textKey: guardianDateOfBirthErrorMessage)
            }
            formField("Số điện thoại người giám hộ", text: $viewModel.guardianPhoneNumber, placeholder: "(+84) 912 345 678", keyboardType: .phonePad)
            genderPicker("Giới tính người giám hộ", selection: $viewModel.guardianGender)
            formField("Địa chỉ người giám hộ", text: $viewModel.guardianAddress, placeholder: "123 Abc, Bình Hưng, TP.HCM")
        }
    }

    private func formField(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AppFont.poppinsRegular.of(size: 12))
                .foregroundColor(.secondaryText)
            TextField(
                "",
                text: text,
                prompt: Text(placeholder)
                    .foregroundColor(.white.opacity(0.45))
            )
            .foregroundColor(.white)
            .keyboardType(keyboardType)
            .font(AppFont.poppinsMedium.of(size: 12))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.darkCocoa)
            .cornerRadius(8)
            .frame(height: 36)
        }
    }

    private func genderPicker(_ title: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AppFont.poppinsRegular.of(size: 12))
                .foregroundColor(.secondaryText)
            Menu {
                Button("Nam") {
                    selection.wrappedValue = "male"
                }
                Button("Nữ") {
                    selection.wrappedValue = "female"
                }
                Button("Khác") {
                    selection.wrappedValue = "other"
                }
            } label: {
                HStack {
                    Text(genderDisplayName(selection.wrappedValue))
                        .font(AppFont.poppinsMedium.of(size: 12))
                        .foregroundColor(selection.wrappedValue.isEmpty ? .white.opacity(0.7) : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.darkCocoa)
                .cornerRadius(8)
                .frame(height: 36)
            }
        }
    }

    private func genderDisplayName(_ value: String) -> String {
        switch value {
        case "male":
            return "Nam"
        case "female":
            return "Nữ"
        case "other":
            return "Khác"
        default:
            return "Chọn giới tính"
        }
    }
}

private struct DateInputField: View {
    let title: String
    @Binding var text: String
    let onInputChange: (String, Bool) -> String

    @State private var displayText: String

    init(title: String, text: Binding<String>, onInputChange: @escaping (String, Bool) -> String) {
        self.title = title
        self._text = text
        self.onInputChange = onInputChange
        self._displayText = State(initialValue: text.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AppFont.poppinsRegular.of(size: 12))
                .foregroundColor(.secondaryText)
            TextField(
                "",
                text: $displayText,
                prompt: Text("DD/MM/YYYY")
                    .foregroundColor(.white.opacity(0.35))
            )
            .foregroundColor(.white)
            .keyboardType(.numberPad)
            .font(AppFont.poppinsMedium.of(size: 12))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.darkCocoa)
            .cornerRadius(8)
            .frame(height: 36)
            .onChange(of: displayText) { newValue in
                let isDeleting = newValue.count < text.count
                let formattedValue = onInputChange(newValue, isDeleting)
                if displayText != formattedValue {
                    displayText = formattedValue
                }
            }
            .onChange(of: text) { newValue in
                if displayText != newValue {
                    displayText = newValue
                }
            }
        }
    }
}

#Preview {
    UpdateAccountInformation(
        authManager: DefaultAuthManager.Builder().build(),
        onSuccess: { isSuccess in
            print("Success: \(isSuccess)")
        }
    )
}
