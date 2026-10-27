import SwiftUI

// 避开 Xcode 27 的 State 宏，保持 iOS 18 可用的属性包装器存储。
public typealias StoredState<Value> = SwiftUI.State<Value>
