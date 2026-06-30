import SwiftUI

struct PhoneNumberInputText: View {
    @Binding var phoneNumber: String
    var onSubmit: (() -> Void)?
    var placeholder: String = "(+84) 912 345 6780"
    var height: CGFloat = 36
    
    var body: some View {
        TextField(
            "",
            text: $phoneNumber,
            prompt: Text(placeholder)
                .foregroundColor(.white.opacity(0.35))
        )
        .foregroundColor(.white)
        .keyboardType(.phonePad)
        .font(AppFont.poppinsMedium.of(size: 12))
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.darkCocoa)
        .onSubmit {
            onSubmit?()
        }
        .cornerRadius(8)
        .frame(height: height)
    }
}

#Preview {
    PhoneNumberInputText(
        phoneNumber: .constant(""),
        onSubmit: {
        
        }
    )
    .padding()
}
