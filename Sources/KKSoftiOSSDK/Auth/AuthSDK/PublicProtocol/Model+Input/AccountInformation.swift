//
//  AccountInformation.swift
//  AuthSDK
//

import Foundation

public struct AccountInformation: Encodable, Equatable, Hashable {
    public let avatarUrl: String
    public let displayName: String
    public let personalInfo: PersonalInfo
    public let guardianInfo: GuardianInfo
    public var sign: String

    public init(
        avatarUrl: String,
        displayName: String,
        personalInfo: PersonalInfo,
        guardianInfo: GuardianInfo,
        sign: String = ""
    ) {
        self.avatarUrl = avatarUrl
        self.displayName = displayName
        self.personalInfo = personalInfo
        self.guardianInfo = guardianInfo
        self.sign = sign
    }
}

public struct PersonalInfo: Encodable, Equatable, Hashable {
    public let dob: String
    public let fullName: String
    public let gender: String
    public let address: String
    public let idNumber: String
    public let idIssueDate: String
    public let idIssuePlace: String
    public let nationality: String
    public let locked: Bool
    public let phoneNumber: String
    public let upldIdFront: String
    public let upldIdBack: String
    public let upldPhoto: String
    public let upldBirthCertificate: String
    public let upldGuardianConsent: String

    public init(
        dob: String,
        fullName: String,
        gender: String,
        address: String,
        idNumber: String,
        idIssueDate: String,
        idIssuePlace: String,
        nationality: String,
        locked: Bool,
        upldIdFront: String,
        upldIdBack: String,
        upldPhoto: String,
        upldBirthCertificate: String,
        upldGuardianConsent: String,
        phoneNumber: String = ""
    ) {
        self.dob = dob
        self.fullName = fullName
        self.gender = gender
        self.address = address
        self.idNumber = idNumber
        self.idIssueDate = idIssueDate
        self.idIssuePlace = idIssuePlace
        self.nationality = nationality
        self.locked = locked
        self.phoneNumber = phoneNumber
        self.upldIdFront = upldIdFront
        self.upldIdBack = upldIdBack
        self.upldPhoto = upldPhoto
        self.upldBirthCertificate = upldBirthCertificate
        self.upldGuardianConsent = upldGuardianConsent
    }
}

public struct GuardianInfo: Encodable, Equatable, Hashable {
    public let fullName: String
    public let gender: String
    public let dob: String
    public let address: String
    public let idNumber: String
    public let idIssueDate: String
    public let idIssuePlace: String
    public let relation: String
    public let locked: Bool
    public let phoneNumber: String
    public let otpVerifiedToken: String?

    public init(
        fullName: String,
        gender: String,
        dob: String,
        address: String,
        idNumber: String,
        idIssueDate: String,
        idIssuePlace: String,
        relation: String,
        locked: Bool,
        phoneNumber: String = "",
        otpVerifiedToken: String? = nil
    ) {
        self.fullName = fullName
        self.gender = gender
        self.dob = dob
        self.address = address
        self.idNumber = idNumber
        self.idIssueDate = idIssueDate
        self.idIssuePlace = idIssuePlace
        self.relation = relation
        self.locked = locked
        self.phoneNumber = phoneNumber
        self.otpVerifiedToken = otpVerifiedToken
    }
}
