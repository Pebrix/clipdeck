//
//  SettingsView.swift
//  clipdeck
//
//  Created by Anupam Srivastava on 02/02/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("clipdeck.trimSpaces") private var trimSpaces: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Preferences")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider()

            // Settings list
            VStack(alignment: .leading, spacing: 0) {
                settingRow(
                    title: "Trim spaces from start and end",
                    description: "Remove leading and trailing whitespace from clips when added",
                    toggle: $trimSpaces
                )
            }
            .padding(.vertical, 12)

            Spacer()
        }
        .frame(width: 400, height: 250)
    }

    private func settingRow(title: String, description: String, toggle: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: toggle)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
}
