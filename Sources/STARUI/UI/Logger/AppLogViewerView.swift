import Combine
import STARCore
import SwiftUI

/// 日志查看页面
public struct AppLogViewerView: View {
    @StoredState
    private var logs: [AppLogEntry] = AppLogger.currentLogs()

    @StoredState
    private var searchText: String = ""

    @StoredState
    private var selectedSubsystem: String?

    @StoredState
    private var selectedCategory: String?

    @StoredState
    private var selectedType: AppLogType?

    @StoredState
    private var expandedIDs: Set<UUID> = []

    public init() {}

    public var body: some View {
        List {
            filterSection

            if filteredLogs.isEmpty {
                emptySection
            } else {
                ForEach(filteredLogs) { entry in
                    logRow(entry)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                deleteLog(id: entry.id)
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Logs")
        .searchable(text: $searchText, prompt: "Search logs")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear All", role: .destructive) {
                    clearAllLogs()
                }
                .disabled(logs.isEmpty)
            }
        }
        .onAppear {
            reloadLogs()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appLoggerLogsDidChange)) { _ in
            reloadLogs()
        }
    }

    /// 过滤区
    private var filterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    subsystemMenu
                    categoryMenu
                    typeMenu
                }
                .padding(.vertical, 6)
            }
        }
    }

    /// 空状态区
    private var emptySection: some View {
        Section {
            VStack(alignment: .center, spacing: 8) {
                Text(logs.isEmpty ? "No logs yet" : "No matching logs")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .listRowBackground(Color.clear)
        }
    }

    /// 子系统筛选菜单
    private var subsystemMenu: some View {
        Menu {
            Button("All Subsystems") {
                selectedSubsystem = nil
            }

            ForEach(subsystemOptions, id: \.self) { subsystem in
                Button(subsystem) {
                    selectedSubsystem = subsystem
                }
            }
        } label: {
            filterChip(title: selectedSubsystem ?? "All Subsystems")
        }
    }

    /// 分类筛选菜单
    private var categoryMenu: some View {
        Menu {
            Button("All Categories") {
                selectedCategory = nil
            }

            ForEach(categoryOptions, id: \.self) { category in
                Button(category) {
                    selectedCategory = category
                }
            }
        } label: {
            filterChip(title: selectedCategory ?? "All Categories")
        }
    }

    /// 类型筛选菜单
    private var typeMenu: some View {
        Menu {
            Button("All Types") {
                selectedType = nil
            }

            ForEach(typeOptions, id: \.rawValue) { type in
                Button(typeDisplayName(type)) {
                    selectedType = type
                }
            }
        } label: {
            filterChip(title: selectedType.map(typeDisplayName) ?? "All Types")
        }
    }

    /// 筛选胶囊
    private func filterChip(title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .font(.caption)
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }

    /// 单条日志行
    private func logRow(_ entry: AppLogEntry) -> some View {
        let isExpanded = expandedIDs.contains(entry.id)

        return Button {
            toggleExpanded(id: entry.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(entry.subsystem)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(entry.timestamp.formatted(date: .abbreviated, time: .standard))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Text(entry.category)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    typeTag(for: entry.type)
                }

                Text(isExpanded ? entry.message : entry.shortMessage)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(isExpanded ? nil : 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 日志类型标签
    private func typeTag(for type: AppLogType) -> some View {
        Text(type.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(typeColor(for: type).opacity(0.15))
            .foregroundStyle(typeColor(for: type))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    /// 过滤后日志
    private var filteredLogs: [AppLogEntry] {
        logs.filter { entry in
            matchesSubsystem(entry) &&
                matchesCategory(entry) &&
                matchesType(entry) &&
                matchesSearchText(entry)
        }
    }

    /// 子系统可选项
    private var subsystemOptions: [String] {
        Set(logs.map(\.subsystem)).sorted()
    }

    /// 分类可选项
    private var categoryOptions: [String] {
        Set(logs.map(\.category)).sorted()
    }

    /// 类型可选项
    private var typeOptions: [AppLogType] {
        logs.reduce(into: [AppLogType]()) { partialResult, entry in
            if !partialResult.contains(where: { $0 == entry.type }) {
                partialResult.append(entry.type)
            }
        }
        .sorted { $0.rawValue < $1.rawValue }
    }

    /// 重新加载日志
    private func reloadLogs() {
        logs = AppLogger.currentLogs()
        normalizeFilters()
    }

    /// 删除单条日志
    private func deleteLog(id: UUID) {
        AppLogger.deleteLog(id: id)
        expandedIDs.remove(id)
        reloadLogs()
    }

    /// 清空日志
    private func clearAllLogs() {
        AppLogger.clearLogs()
        expandedIDs.removeAll(keepingCapacity: true)
        reloadLogs()
    }

    /// 切换展开状态
    private func toggleExpanded(id: UUID) {
        if expandedIDs.contains(id) {
            expandedIDs.remove(id)
        } else {
            expandedIDs.insert(id)
        }
    }

    /// 子系统匹配
    private func matchesSubsystem(_ entry: AppLogEntry) -> Bool {
        guard let selectedSubsystem else { return true }
        return entry.subsystem == selectedSubsystem
    }

    /// 分类匹配
    private func matchesCategory(_ entry: AppLogEntry) -> Bool {
        guard let selectedCategory else { return true }
        return entry.category == selectedCategory
    }

    /// 类型匹配
    private func matchesType(_ entry: AppLogEntry) -> Bool {
        guard let selectedType else { return true }
        return entry.type == selectedType
    }

    /// 搜索词匹配
    private func matchesSearchText(_ entry: AppLogEntry) -> Bool {
        guard !searchText.isEmpty else { return true }

        let keyword = searchText.lowercased()
        return entry.message.lowercased().contains(keyword) ||
            entry.subsystem.lowercased().contains(keyword) ||
            entry.category.lowercased().contains(keyword) ||
            entry.type.rawValue.lowercased().contains(keyword)
    }

    /// 过滤器归一化
    private func normalizeFilters() {
        if let selectedSubsystem, !subsystemOptions.contains(selectedSubsystem) {
            self.selectedSubsystem = nil
        }

        if let selectedCategory, !categoryOptions.contains(selectedCategory) {
            self.selectedCategory = nil
        }

        if let selectedType, !typeOptions.contains(where: { $0 == selectedType }) {
            self.selectedType = nil
        }
    }

    /// 类型展示文案
    private func typeDisplayName(_ type: AppLogType) -> String {
        type.rawValue.capitalized
    }

    /// 类型颜色
    private func typeColor(for type: AppLogType) -> Color {
        switch type {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .debug:
            return .purple
        case .error:
            return .red
        case .critical:
            return .pink
        }
    }
}
