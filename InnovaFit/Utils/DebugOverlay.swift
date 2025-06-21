import SwiftUI

struct DebugOverlay: View {
    let debugText: String
    @Binding var isVisible: Bool

    var body: some View {
        //#if DEBUG || targetEnvironment(simulator)
        if isVisible {
            VStack {
                Spacer()
                ScrollView {
                    Text(debugText)
                        .font(.system(size: 12, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.85))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                        .padding()
                }
            }
            .transition(.opacity)
            .zIndex(1000)
        }
        //#endif
    }
}

