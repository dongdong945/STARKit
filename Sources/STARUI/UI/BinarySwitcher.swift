import SwiftUI

/// 可用于二元切换的协议
public protocol BinarySwitchable: Hashable, CaseIterable, Sendable {
    /// 选项显示名称
    var displayName: String { get }
}

/// 通用二元切换器组件
public struct BinarySwitcher<Option: BinarySwitchable>: View {
    @Binding
    private var selectedOption: Option
    private let selectedColor: Color
    private let normalColor: Color
    private let labelFont: Font

    public init(
        selectedOption: Binding<Option>,
        selectedColor: Color = .accentColor,
        normalColor: Color = .secondary,
        labelFont: Font = .system(size: 15, weight: .regular)
    ) {
        _selectedOption = selectedOption
        self.selectedColor = selectedColor
        self.normalColor = normalColor
        self.labelFont = labelFont
    }

    public var body: some View {
        let allCases = Array(Option.allCases)

        HStack(spacing: 12) {
            if let first = allCases.first {
                Text(first.displayName)
                    .font(labelFont)
                    .foregroundStyle(selectedOption == first ? selectedColor : normalColor)
            }

            Toggle("", isOn: Binding(
                get: { selectedOption == allCases.last },
                set: { isOn in
                    selectedOption = isOn ? (allCases.last ?? selectedOption) : (allCases.first ?? selectedOption)
                }
            ))
            .labelsHidden()
            .tint(selectedColor)

            if let last = allCases.last {
                Text(last.displayName)
                    .font(labelFont)
                    .foregroundStyle(selectedOption == last ? selectedColor : normalColor)
            }
        }
    }
}
