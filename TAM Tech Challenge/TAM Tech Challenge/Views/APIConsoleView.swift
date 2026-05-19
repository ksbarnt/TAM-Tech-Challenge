import SwiftUI

struct APIConsoleView: View {

    @EnvironmentObject var authManager: OIDCAuthManager
    @StateObject private var viewModel: APIViewModel

    init(authManager: OIDCAuthManager) {
        _viewModel = StateObject(wrappedValue: APIViewModel(authManager: authManager))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Quick-action method buttons ───────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        MethodButton("GET",    color: .green)  { await viewModel.demoGET() }
                        MethodButton("POST",   color: .blue)   { await viewModel.demoPOST() }
                        MethodButton("PUT",    color: .orange) { await viewModel.demoPUT() }
                        MethodButton("PATCH",  color: .purple) { await viewModel.demoPATCH() }
                        MethodButton("DELETE", color: .red)    { await viewModel.demoDELETE() }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(.bar)

                Divider()

                // ── Response log ──────────────────────────────────────────────
                if viewModel.logEntries.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Requests Yet",
                        systemImage: "network",
                        description: Text("Tap a verb or Run All to make authenticated API calls.")
                    )
                } else {
                    List(viewModel.logEntries) { entry in
                        LogEntryRow(entry: entry)
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                    .listStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("API Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                    Button {
                        Task { await viewModel.runAllDemos() }
                    } label: {
                        Label("Run All", systemImage: "play.fill")
                    }
                    .disabled(viewModel.isLoading)

                    Button {
                        viewModel.logEntries = []
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(viewModel.logEntries.isEmpty)
                }
            }
        }
    }
}

// ── Method button ─────────────────────────────────────────────────────────────

private struct MethodButton: View {
    let label : String
    let color : Color
    let action: () async -> Void

    init(_ label: String, color: Color, action: @escaping () async -> Void) {
        self.label  = label
        self.color  = color
        self.action = action
    }

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Text(label)
                .font(.caption.monospaced().bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// ── Log entry row ─────────────────────────────────────────────────────────────

private struct LogEntryRow: View {

    let entry: APILogEntry

    private var methodColor: Color {
        switch entry.method {
        case "GET":    return .green
        case "POST":   return .blue
        case "PUT":    return .orange
        case "PATCH":  return .purple
        case "DELETE": return .red
        default:       return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(entry.method)
                    .font(.caption.monospaced().bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(methodColor.opacity(0.15))
                    .foregroundStyle(methodColor)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                Text(entry.path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Image(systemName: entry.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(entry.isError ? .red : .green)
                    .font(.caption)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(entry.result)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(entry.isError ? .red : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 120)
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}
