//
//  UpdateAccountInformationViewModel.swift
//  AuthSDK
//
//  Created by KKSOFT on 5/6/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class UpdateAccountInformationViewModel: OpenViewModel {
    enum SubmitMode {
        case updateExisting
        case collectForRegistration
    }

    enum InfoStep {
        case personal
        case guardian
    }

    @Published var fullName = ""
    @Published var phoneNumber = ""
    @Published var dateOfBirth = ""
    @Published var dateOfBirthErrorMessage: LocalizedStringKey? = nil
    @Published var gender = ""
    @Published var address = ""
    @Published var idNumber = ""
    @Published var isAcceptedTerm = false
    @Published var isOver16 = true

    @Published var guardianFullName = ""
    @Published var guardianPhoneNumber = ""
    @Published var guardianDateOfBirth = ""
    @Published var guardianDateOfBirthErrorMessage: LocalizedStringKey? = nil
    @Published var guardianGender = ""
    @Published var guardianAddress = ""
    @Published var guardianIdNumber = ""
    @Published var guardianRelation = ""

    @Published var isOTPRequestManyTime = false
    @Published var isAccountExisted = false
    @Published var errorMessage: LocalizedStringKey? = nil

    let authManager: AuthManager
    let mode: SubmitMode
    let screenStep: InfoStep
    let isAtLeast16Confirmed: Bool

    private let baseAccountInformation: AccountInformation?
    private let onSuccess: (Bool) -> Void
    private let onPersonalInfoReady: (AccountInformation) -> Void
    private let onRegistrationInfoReady: (AccountInformation, OTPSendableResponse?) -> Void

    init(authManager: AuthManager, onSuccess: @escaping (Bool) -> Void = { _ in }) {
        self.onSuccess = onSuccess
        self.onPersonalInfoReady = { _ in }
        self.onRegistrationInfoReady = { _, _ in }
        self.authManager = authManager
        self.mode = .updateExisting
        self.screenStep = .personal
        self.isAtLeast16Confirmed = true
        self.baseAccountInformation = nil
        super.init()
    }

    init(
        authManager: AuthManager,
        phoneNumber: String,
        isAtLeast16Confirmed: Bool,
        screenStep: InfoStep = .personal,
        baseAccountInformation: AccountInformation? = nil,
        onPersonalInfoReady: @escaping (AccountInformation) -> Void = { _ in },
        onRegistrationInfoReady: @escaping (AccountInformation, OTPSendableResponse?) -> Void
    ) {
        self.onSuccess = { _ in }
        self.onPersonalInfoReady = onPersonalInfoReady
        self.onRegistrationInfoReady = onRegistrationInfoReady
        self.authManager = authManager
        self.mode = .collectForRegistration
        self.screenStep = screenStep
        self.isAtLeast16Confirmed = isAtLeast16Confirmed
        self.baseAccountInformation = baseAccountInformation
        super.init()
        self.phoneNumber = phoneNumber.trimmedVietnamPhoneNumber()
    }

    var screenTitle: String {
        switch screenStep {
        case .personal:
            return "Thông tin cá nhân"
        case .guardian:
            return "Thông tin người giám hộ"
        }
    }

    var stepIndex: Int {
        switch screenStep {
        case .personal:
            return 3
        case .guardian:
            return 4
        }
    }

    var totalStepCount: Int {
        switch screenStep {
        case .personal:
            return requiresGuardianInfo ? 6 : 4
        case .guardian:
            return 6
        }
    }

    var isPrimaryButtonEnabled: Bool {
        switch screenStep {
        case .personal:
            return (!shouldShowTerms || isAcceptedTerm) && isPersonalInfoValid
        case .guardian:
            return isGuardianInfoValid
        }
    }

    var requiresGuardianInfo: Bool {
        !isAtLeast16Confirmed || isDateOfBirthUnder16
    }

    var shouldShowTerms: Bool {
        mode == .updateExisting
    }

    var shouldShowPhoneNumber: Bool {
        mode == .updateExisting
    }

    private var isPersonalInfoValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && isDateOfBirthInputValid
        && (!shouldShowPhoneNumber || phoneNumber.isValidPhoneNumber())
    }

    private var isGuardianInfoValid: Bool {
        !guardianFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && isGuardianDateOfBirthInputValid
        && guardianPhoneNumber.isValidPhoneNumber()
        && guardianPhoneNumber.trimmedVietnamPhoneNumber() != phoneNumber.trimmedVietnamPhoneNumber()
    }

    private var isDateOfBirthInputValid: Bool {
        let value = dateOfBirth.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || (dateOfBirthErrorMessage == nil && parsedDateOfBirth != nil)
    }

    private var isGuardianDateOfBirthInputValid: Bool {
        let value = guardianDateOfBirth.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty || (guardianDateOfBirthErrorMessage == nil && parsedGuardianDateOfBirth != nil)
    }

    private var isDateOfBirthUnder16: Bool {
        guard let date = parsedDateOfBirth else { return false }
        return age(on: date) < 16
    }

    private var parsedDateOfBirth: Date? {
        parseDate(dateOfBirth)
    }

    private var parsedGuardianDateOfBirth: Date? {
        parseDate(guardianDateOfBirth)
    }

    private func resetState() {
        isLoading = false
        isOTPRequestManyTime = false
        isAccountExisted = false
        errorMessage = nil
    }

    func submit() {
        resetState()

        switch mode {
        case .collectForRegistration:
            submitRegistrationInfo()
        case .updateExisting:
            guard let accountInformation = makePersonalAccountInformation() else {
                errorMessage = .sdkAsset("unknown_error_message")
                return
            }
            performRequest(
                publisher: authManager.updateAccountInfo(data: accountInformation),
                onSuccess: { [weak self] isSuccess in
                    guard let self else { return }
                    self.onSuccess(isSuccess)
                }
            )
        }
    }

    private func submitRegistrationInfo() {
        switch screenStep {
        case .personal:
            guard let accountInformation = makePersonalAccountInformation() else {
                errorMessage = .sdkAsset("unknown_error_message")
                return
            }

            if requiresGuardianInfo {
                onPersonalInfoReady(accountInformation)
            } else {
                onRegistrationInfoReady(accountInformation, nil)
            }
        case .guardian:
            guard let accountInformation = makeGuardianAccountInformation() else {
                errorMessage = .sdkAsset("unknown_error_message")
                return
            }
            requestGuardianOTP(accountInformation: accountInformation)
        }
    }

    private func performRequest<P: Publisher>(
        publisher: P,
        onSuccess: @escaping (P.Output) -> Void
    ) where P.Failure == Error {
        isLoading = true
        publisher
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .sink { [weak self] completion in
                guard let self else { return }
                if case .failure(let err) = completion {
                    if let apiErr = err as? AuthErrorResponse {
                        self.errorMessage = apiErr.displayMessage(serverFallback: .sdkAsset("server_error"))
                        return
                    }
                    self.errorMessage = .sdkAsset("server_error")
                }
            } receiveValue: { output in
                onSuccess(output)
            }
            .store(in: &cancellables)
    }

    private func requestGuardianOTP(accountInformation: AccountInformation) {
        performRequest(
            publisher: authManager.requestOTP(phone: guardianPhoneNumber.trimmedVietnamPhoneNumber()),
            onSuccess: { [weak self] otpResponse in
                guard let self else { return }
                self.onRegistrationInfoReady(accountInformation, otpResponse)
            }
        )
    }

    private func makePersonalAccountInformation() -> AccountInformation? {
        guard isPersonalInfoValid else { return nil }
        let personalInfo = PersonalInfo(
            dob: dateOfBirth.trimmingCharacters(in: .whitespacesAndNewlines),
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: gender.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            idNumber: idNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            idIssueDate: "",
            idIssuePlace: "",
            nationality: "VN",
            locked: false,
            upldIdFront: "",
            upldIdBack: "",
            upldPhoto: "",
            upldBirthCertificate: "",
            upldGuardianConsent: "",
            phoneNumber: phoneNumber.trimmedVietnamPhoneNumber()
        )

        return AccountInformation(
            avatarUrl: "",
            displayName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            personalInfo: personalInfo,
            guardianInfo: emptyGuardianInfo
        )
    }

    private func makeGuardianAccountInformation() -> AccountInformation? {
        guard isGuardianInfoValid, let baseAccountInformation else { return nil }
        let guardianInfo = GuardianInfo(
            fullName: guardianFullName.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: guardianGender.trimmingCharacters(in: .whitespacesAndNewlines),
            dob: guardianDateOfBirth.trimmingCharacters(in: .whitespacesAndNewlines),
            address: guardianAddress.trimmingCharacters(in: .whitespacesAndNewlines),
            idNumber: guardianIdNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            idIssueDate: "",
            idIssuePlace: "",
            relation: guardianRelation.trimmingCharacters(in: .whitespacesAndNewlines),
            locked: false,
            phoneNumber: guardianPhoneNumber.trimmedVietnamPhoneNumber()
        )

        return AccountInformation(
            avatarUrl: baseAccountInformation.avatarUrl,
            displayName: baseAccountInformation.displayName,
            personalInfo: baseAccountInformation.personalInfo,
            guardianInfo: guardianInfo
        )
    }

    private var emptyGuardianInfo: GuardianInfo {
        GuardianInfo(
            fullName: "",
            gender: "",
            dob: "",
            address: "",
            idNumber: "",
            idIssueDate: "",
            idIssuePlace: "",
            relation: "",
            locked: false,
            phoneNumber: ""
        )
    }

    func updateDateOfBirthInput(_ value: String, isDeleting: Bool) -> String {
        let result = formattedDateInput(value, isDeleting: isDeleting)
        dateOfBirth = result.value
        dateOfBirthErrorMessage = result.errorMessage
        return result.value
    }

    func updateGuardianDateOfBirthInput(_ value: String, isDeleting: Bool) -> String {
        let result = formattedDateInput(value, isDeleting: isDeleting)
        guardianDateOfBirth = result.value
        guardianDateOfBirthErrorMessage = result.errorMessage
        return result.value
    }

    private func formattedDateInput(_ value: String, isDeleting: Bool) -> (value: String, errorMessage: LocalizedStringKey?) {
        let digits = String(value.filter { $0.isNumber }.prefix(8))
        let errorMessage = dateInputError(for: digits)
        let formattedValue = formatDateDigits(digits, shouldAdvance: !isDeleting && errorMessage == nil)
        return (formattedValue, errorMessage)
    }

    private func formatDateDigits(_ digits: String, shouldAdvance: Bool) -> String {
        guard !digits.isEmpty else { return "" }

        let day = String(digits.prefix(2))
        guard digits.count > 2 else {
            return digits.count == 2 && shouldAdvance ? "\(day)/" : day
        }

        let monthStart = digits.index(digits.startIndex, offsetBy: 2)
        let monthLength = min(2, digits.count - 2)
        let monthEnd = digits.index(monthStart, offsetBy: monthLength)
        let month = String(digits[monthStart..<monthEnd])
        guard digits.count > 4 else {
            let value = "\(day)/\(month)"
            return digits.count == 4 && shouldAdvance ? "\(value)/" : value
        }

        let yearStart = digits.index(digits.startIndex, offsetBy: 4)
        let year = String(digits[yearStart...])
        return "\(day)/\(month)/\(year)"
    }

    private func dateInputError(for digits: String) -> LocalizedStringKey? {
        guard !digits.isEmpty else { return nil }

        var day: Int?
        if digits.count >= 2 {
            let dayText = String(digits.prefix(2))
            guard let parsedDay = Int(dayText), (1...31).contains(parsedDay) else {
                return LocalizedStringKey("Ngày không hợp lệ")
            }
            day = parsedDay
        }

        var month: Int?
        if digits.count >= 4 {
            let monthStart = digits.index(digits.startIndex, offsetBy: 2)
            let monthEnd = digits.index(monthStart, offsetBy: 2)
            let monthText = String(digits[monthStart..<monthEnd])
            guard let parsedMonth = Int(monthText), (1...12).contains(parsedMonth) else {
                return LocalizedStringKey("Tháng không hợp lệ")
            }
            month = parsedMonth
        }

        var year: Int?
        if digits.count == 8 {
            let yearStart = digits.index(digits.startIndex, offsetBy: 4)
            year = Int(digits[yearStart...])
        }

        if let day, let month, day > maximumDay(in: month, year: year) {
            return LocalizedStringKey("Ngày không hợp lệ")
        }

        guard digits.count == 8 else { return nil }
        let formattedValue = formattedDateInputForValidation(digits)
        guard let date = parseDate(formattedValue), date <= Date() else {
            return LocalizedStringKey("Ngày sinh không hợp lệ")
        }
        return nil
    }

    private func formattedDateInputForValidation(_ digits: String) -> String {
        let day = digits.prefix(2)
        let monthStart = digits.index(digits.startIndex, offsetBy: 2)
        let monthEnd = digits.index(monthStart, offsetBy: 2)
        let yearStart = digits.index(digits.startIndex, offsetBy: 4)
        let month = digits[monthStart..<monthEnd]
        let year = digits[yearStart...]
        return "\(day)/\(month)/\(year)"
    }

    private func maximumDay(in month: Int, year: Int?) -> Int {
        switch month {
        case 2:
            guard let year else { return 29 }
            return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }

    private func isLeapYear(_ year: Int) -> Bool {
        (year.isMultiple(of: 4) && !year.isMultiple(of: 100)) || year.isMultiple(of: 400)
    }

    private func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.isLenient = false
        return formatter.date(from: value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func age(on birthDate: Date) -> Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    override func handleApiError(_ apiError: AuthErrorResponse) {
        switch apiError.code {
        case .OTPRequestManyTime:
            isOTPRequestManyTime = true
            errorMessage = apiError.displayMessage(serverFallback: .sdkAsset("otp_request_many_times"))
        case .SocialAccountLinked:
            isAccountExisted = true
            errorMessage = apiError.displayMessage(serverFallback: .sdkAsset("account_existed"))
        default:
            super.handleApiError(apiError)
            errorMessage = apiError.displayMessage(serverFallback: .sdkAsset("unknown_error_message"))
        }
        onSuccess(false)
    }
}
