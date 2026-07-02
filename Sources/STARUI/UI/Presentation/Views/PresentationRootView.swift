import SwiftUI

/// Presentation 根视图（封装递归构建逻辑）
public struct PresentationRootView<ViewMapper: PresentationViewMapping>: View {
    /// Presentation 助手
    @Bindable
    public var helper: PresentationHelper

    /// 视图映射器
    public let viewMapper: ViewMapper

    public init(helper: PresentationHelper, viewMapper: ViewMapper) {
        self.helper = helper
        self.viewMapper = viewMapper
    }

    public var body: some View {
        Color.clear
            .sheet(item: makeBinding(at: 0, for: .sheet) as Binding<SheetWrapper?>) { wrapper in
                presentationView(for: wrapper.item, at: 0)
            }
            .fullScreenCover(item: makeBinding(at: 0, for: .fullScreenCover) as Binding<CoverWrapper?>) { wrapper in
                presentationView(for: wrapper.item, at: 0)
            }
    }

    /// 递归构建 Presentation 视图
    private func presentationView(for item: PresentationItem, at index: Int) -> AnyView {
        let contentView = viewMapper.view(for: item.viewType)
        let nextIndex = index + 1

        let result = contentView
            .sheet(item: makeBinding(at: nextIndex, for: .sheet) as Binding<SheetWrapper?>) { wrapper in
                presentationView(for: wrapper.item, at: nextIndex)
            }
            .fullScreenCover(item: makeBinding(at: nextIndex, for: .fullScreenCover) as Binding<CoverWrapper?>) { wrapper in
                presentationView(for: wrapper.item, at: nextIndex)
            }

        return AnyView(result)
    }

    /// 统一的 Binding 生成器
    private func makeBinding<Wrapper: PresentationWrapping>(
        at index: Int,
        for style: PresentationStyle
    ) -> Binding<Wrapper?> {
        Binding(
            get: {
                guard let item = helper.item(at: index),
                      item.style == style else { return nil }
                return Wrapper(item: item)
            },
            set: { newValue in
                if newValue == nil {
                    if index == 0 {
                        helper.dismissAll()
                    } else {
                        helper.dismissFrom(index: index - 1)
                    }
                }
            }
        )
    }
}
