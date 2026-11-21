import SwiftUI

/// A clean, customizable linear progress bar component.
public struct ProgressBarView: View {
    public let value: Double // Expected 0.0 to 100.0
    public let tintColor: Color
    public let height: CGFloat
    public let showLabel: Bool
    
    public init(
        value: Double,
        tintColor: Color = .blue,
        height: CGFloat = 8,
        showLabel: Bool = false
    ) {
        self.value = max(0.0, min(100.0, value))
        self.tintColor = tintColor
        self.height = height
        self.showLabel = showLabel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(tintColor.opacity(0.18))
                        .frame(height: height)
                    
                    Capsule()
                        .fill(tintColor)
                        .frame(width: max(0, geometry.size.width * CGFloat(value / 100.0)), height: height)
                        .animation(.easeInOut(duration: 0.3), value: value)
                }
            }
            .frame(height: height)
            
            if showLabel {
                HStack {
                    Spacer()
                    Text(String(format: "%.0f%%", value))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(tintColor)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBarView(value: 75.0, tintColor: .green, height: 10, showLabel: true)
        ProgressBarView(value: 33.3, tintColor: .orange, height: 8, showLabel: true)
        ProgressBarView(value: 0.0, tintColor: .blue, height: 6, showLabel: false)
    }
    .padding()
}
