import SwiftUI

struct SettingsPlaceholderView: View {
    @EnvironmentObject private var store: FocusPetStore

    var body: some View {
        FocusPetSceneScaffold(title: "设置", subtitle: "选择一个你更想一起待着的小伙伴。") {
            SoftPanel {
                Text("陪伴动物")
                    .font(FocusPetTheme.Typography.headline)

                PetSelectionBar(selectedPet: store.settings.defaultPet) { pet in
                    store.updateDefaultPet(pet)
                }
            }

            SoftPanel {
                Text("默认设置")
                    .font(FocusPetTheme.Typography.headline)
                settingsRow("默认动物", store.settings.defaultPet.displayName)
                settingsRow("计时模式", store.settings.defaultTimerMode.displayName)
                settingsRow("默认时长", store.settings.defaultCountdownText)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(FocusPetTheme.Typography.body)
                .foregroundStyle(FocusPetTheme.Palette.ink)
            Spacer()
            Text(value)
                .font(FocusPetTheme.Typography.subheadline)
                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
        }
    }
}
