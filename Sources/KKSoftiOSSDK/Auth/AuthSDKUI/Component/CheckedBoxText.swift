import SwiftUI

struct CheckedBoxText: View {
    
    @Binding
    var isChecked: Bool
    private let text: LocalizedStringKey
    private let font: Font
    private let onToggle: ((Bool) -> Void)?
    private let lineLimit: Int
    let highlight: Bool
    private var attributedText: AttributedString? = nil
    
    init(
        lineLimit: Int = 1,
        isChecked: Binding<Bool>,
        text: LocalizedStringKey,
        font: Font = AppFont.poppinsLight.of(size: 10),
        highlight: Bool = false,
        attributedText: AttributedString? = nil,
        onToggle: ((Bool) -> Void)? = nil
    ) {
        self._isChecked = isChecked
        self.text = text
        self.font = font
        self.onToggle = onToggle
        self.lineLimit = lineLimit
        self.highlight = highlight
        self.attributedText = attributedText
    }
    
    var attributed: AttributedString {
            var str = AttributedString("Tôi đồng ý với ")
            
            // "điều khoản" link
            var dk = AttributedString("điều khoản")
            dk.foregroundColor = .blue
            dk.underlineStyle = .single
            dk.link = URL(string: "https://kksoft.vn/dieu-khoan")
            str.append(dk)
            
            str.append(AttributedString(" và "))
            
            // "chính sách bảo mật" link
            var csbm = AttributedString("chính sách bảo mật")
            csbm.foregroundColor = .blue
            csbm.underlineStyle = .single
            csbm.link = URL(string: "https://kksoft.vn/chinh-sach-bao-mat")
            str.append(csbm)
            
            return str
        }
    
    var body: some View {
        HStack(spacing: 8) {
            Button {
                isChecked.toggle()
                onToggle?(isChecked)
            } label: {
                Image(systemName: isChecked
                      ? "checkmark.square.fill"
                      : "square")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(isChecked ? .blue : .brownish)
            }
            Text(attributedText ?? attributed)
                .font(font)
                .foregroundColor(.grayish)
                .lineLimit(lineLimit)
            Spacer()
        }
        .animation(highlight ? .easeInOut(duration: 0.3).repeatCount(3) : .none, value: highlight)
    }
}

#Preview {
    CheckedBoxText(isChecked: .constant(false), text: .sdkAsset("terms_and_conditions"),
                   onToggle: { isChecked in
    })
    .padding()
}
