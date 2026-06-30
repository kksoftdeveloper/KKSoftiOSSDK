import SwiftUI

private struct PopupModifier<PopupContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let backgroundOpacity: Double
    let dismissOnTapOutside: Bool
    let popupContent: (_ dismiss: @escaping () -> Void) -> PopupContent

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        if dismissOnTapOutside {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }

                popupContent {
                    withAnimation {
                        isPresented = false
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    public func popup<PopupContent: View>(
        isPresented: Binding<Bool>,
        backgroundOpacity: Double = 0.4,
        dismissOnTapOutside: Bool = false,
        @ViewBuilder content: @escaping (_ dismiss: @escaping () -> Void) -> PopupContent
    ) -> some View {
        self.modifier(PopupModifier(
            isPresented: isPresented,
            backgroundOpacity: backgroundOpacity,
            dismissOnTapOutside: dismissOnTapOutside,
            popupContent: content
        ))
    }
}

extension View {
    public func popup<Item: Identifiable, PopupContent: View>(
        item: Binding<Item?>,
        backgroundOpacity: Double = 0.4,
        dismissOnTapOutside: Bool = false,
        @ViewBuilder content: @escaping (_ item: Item, _ dismiss: @escaping () -> Void) -> PopupContent
    ) -> some View {
        self.overlay {
            if let unwrappedItem = item.wrappedValue {
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        if dismissOnTapOutside {
                            withAnimation {
                                item.wrappedValue = nil
                            }
                        }
                    }

                content(unwrappedItem) {
                    withAnimation {
                        item.wrappedValue = nil
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: item.wrappedValue != nil)
    }
}
