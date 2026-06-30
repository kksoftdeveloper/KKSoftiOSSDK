import SwiftUI

struct PhoneNumberInputText: View {
    @Binding var phoneNumber: String
    var onSubmit: (() -> Void)?
    
    var body: some View {
        TextField(
            "",
            text: $phoneNumber,
            prompt: Text("(+84) 912 345 6780")
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
        .frame(height: 36)
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
