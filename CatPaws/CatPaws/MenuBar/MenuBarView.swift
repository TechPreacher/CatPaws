//
//  MenuBarView.swift
//  CatPaws
//
//  Created on 2026-01-15.
//

import SwiftUI

/// Menu bar content view (alternative to popover if using menu-based UI)
struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CatPaws")
                .font(.headline)

            Divider()

            Text("Menu bar app is running")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    MenuBarView()
}
