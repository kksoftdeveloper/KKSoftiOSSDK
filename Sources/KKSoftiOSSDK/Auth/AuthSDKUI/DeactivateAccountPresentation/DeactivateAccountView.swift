//
//  DeactivateAccountView.swift
//  AuthSDK
//
//  Created by X on 6/19/25.
//

import Foundation

import SwiftUI

public struct DeactivateAccountView: View {
    @StateObject var viewModel: DeactivateAccountViewModel
    @SwiftUI.Environment(\.verticalSizeClass) var verticalSizeClass

    private var onClose: () -> Void
    private var onSuccess: () -> Void
    private var onFailure: () -> Void
    
    private let fullWidth = min(UIScreen.main.bounds.size.width, 375)
    
    public init(
        onClose: @escaping () -> Void = { },
        onSuccess: @escaping () -> Void = { },
        onFailure: @escaping () -> Void = { },
        authManager: AuthManager
    ) {
        _viewModel = .init(wrappedValue: DeactivateAccountViewModel(
            authManager: authManager,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onClose: onClose
        ))
        self.onClose = onClose
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
    
    public var body: some View {
        let isLandscape = verticalSizeClass == .compact
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let minValue = min(width, height, CGFloat((isPad ? 440 : Int.max)))
        let contentWidth = isLandscape ? minValue*0.9 : minValue
        content(width: contentWidth)
            .preferredColorScheme(.light)
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
            .overlay(alignment: .topTrailing, content: {
                Button(action: onClose) {
                    Image(sdkAsset: "IconCross")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            
            })
            .overlay(alignment: .top, content: {
                Text(.sdkAsset("deactivate_account_title"))
                    .font(AppFont.fsClanNarrowUltra.of(size: 16))
                    .foregroundColor(.primaryText)
                    .padding(.vertical, 30)
            })
            .frame(width: contentWidth, height: contentWidth)
    }
    
    @ViewBuilder
    private func content(width: CGFloat) -> some View {
        ZStack {
            Image(sdkAsset: "SquareBackground")
                .resizable()
                .frame(width: width)
                .aspectRatio(1, contentMode: .fit)
            
            ScrollView {
                VStack {
                    Text(.sdkAsset("deactivate_account_question_1"))
                        .font(AppFont.poppinsRegular.of(size: 16))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primaryText)
                    Spacer()
                    Text(.sdkAsset("deactivate_account_answer_1_1"))
                        .font(AppFont.poppinsLight.of(size: 12))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primaryText)
                    Spacer()
                    Text(.sdkAsset("deactivate_account_answer_1_2"))
                        .font(AppFont.poppinsLight.of(size: 12))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primaryText)
                    Spacer()
                    Text(.sdkAsset("deactivate_account_answer_1_3"))
                        .font(AppFont.poppinsLight.of(size: 12))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primaryText)
                    Spacer()
                    Text(.sdkAsset("deactivate_account_answer_1_4"))
                        .font(AppFont.poppinsLight.of(size: 12))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primaryText)
                    Spacer()
                    Spacer()
                    Text(.sdkAsset("deactivate_account_question_2"))
                        .font(AppFont.poppinsRegular.of(size: 16))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primaryText)
                    Spacer()
                    Text(.sdkAsset("deactivate_account_answer_2_1"))
                        .font(AppFont.poppinsLight.of(size: 12))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primaryText)
                    Spacer()
                    Text(.sdkAsset("deactivate_account_answer_2_2"))
                        .font(AppFont.poppinsLight.of(size: 12))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primaryText)
                    Spacer()
                    CheckedBoxText(
                        lineLimit: 2,
                        isChecked: $viewModel.isAcceptedTerm,
                        text: .sdkAsset("terms_and_condition_delete_account"),
                        font: AppFont.poppinsSemiBold.of(size: 12),
                        onToggle: { newValue in
                            viewModel.isAcceptedTerm = newValue
                        }
                    )
                }.padding(.horizontal, 16)
            }
            .frame(width: fullWidth*0.8, height: fullWidth*0.65)
        }
        .overlay(alignment: .bottom, content: {
            let primaryButtonWidth = fullWidth*0.46
            PrimaryButton(
                action: {
                    viewModel.deactivateAccount()
                },
                label: {
                    Text(.sdkAsset("confirm"))
                        .font(AppFont.poppinsBold.of(size: 14))
                },
                isDisabled: viewModel.isAcceptedTerm == false
            )
            .frame(width: primaryButtonWidth, height: primaryButtonWidth*0.35)
            .padding(.bottom, -fullWidth/20)
        })
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

#Preview {
    DeactivateAccountView(
        onClose: {
            
        },
        onSuccess: {
            
        }, onFailure: {
            
        }, authManager: DefaultAuthManager.Builder().build())
}
