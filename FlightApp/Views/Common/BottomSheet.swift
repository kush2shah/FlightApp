//
//  BottomSheet.swift
//  FlightApp
//
//  Reusable bottom sheet component with liquid glass design
//

import SwiftUI

struct BottomSheet<Content: View>: View {
    @Environment(\.dismiss) var dismiss

    let title: String
    let showDismissButton: Bool
    let content: Content

    init(
        title: String,
        showDismissButton: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showDismissButton = showDismissButton
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    content
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showDismissButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Presentation Modifiers

extension View {
    /// Present a bottom sheet with standard liquid glass styling
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        showDismissButton: Bool = false,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            BottomSheet(
                title: title,
                showDismissButton: showDismissButton,
                content: content
            )
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
        }
    }

    /// Present a bottom sheet with standard liquid glass styling (item-based)
    func bottomSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        title: String,
        showDismissButton: Bool = false,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        self.sheet(item: item) { selectedItem in
            BottomSheet(
                title: title,
                showDismissButton: showDismissButton,
                content: { content(selectedItem) }
            )
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
        }
    }
}

#Preview {
    VStack {
        Text("Main Content")
    }
    .bottomSheet(
        isPresented: .constant(true),
        title: "Example Sheet"
    ) {
        VStack(spacing: 20) {
            Text("Sheet Content")
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }
}
