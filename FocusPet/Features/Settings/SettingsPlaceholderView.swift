import SwiftUI

struct SettingsPlaceholderView: View {
    @EnvironmentObject private var store: FocusPetStore

    var body: some View {
        FocusPetSceneScaffold(title: "设置", subtitle: nil) {
            SoftPanel {
                Text("陪伴动物")
                    .font(FocusPetTheme.Typography.headline)

                PetSelectionBar(selectedPet: store.settings.defaultPet) { pet in
                    store.updateDefaultPet(pet)
                }
            }

            SoftPanel {
                Text("专注默认值")
                    .font(FocusPetTheme.Typography.headline)

                Picker("默认场景", selection: defaultSceneBinding) {
                    ForEach(SceneType.allCases) { scene in
                        Text(scene.displayName).tag(scene)
                    }
                }
                .pickerStyle(.segmented)

                Picker("计时模式", selection: defaultTimerModeBinding) {
                    ForEach(TimerMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if store.settings.defaultTimerMode == .countDown {
                    Stepper(value: defaultCountdownBinding, in: 5 ... 180, step: 5) {
                        settingsRow("默认时长", store.settings.defaultCountdownText)
                    }
                }
            }

            SoftPanel {
                Text("当前偏好")
                    .font(FocusPetTheme.Typography.headline)

                settingsRow("默认动物", store.settings.defaultPet.displayName)
                settingsRow("默认场景", store.settings.defaultScene.displayName)
                settingsRow("计时模式", store.settings.defaultTimerMode.displayName)
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var defaultSceneBinding: Binding<SceneType> {
        Binding(
            get: { store.settings.defaultScene },
            set: { store.updateDefaultScene($0) }
        )
    }

    private var defaultTimerModeBinding: Binding<TimerMode> {
        Binding(
            get: { store.settings.defaultTimerMode },
            set: { store.updateDefaultTimerMode($0) }
        )
    }

    private var defaultCountdownBinding: Binding<Int> {
        Binding(
            get: { store.settings.defaultCountdownMinutes },
            set: { store.updateDefaultCountdownMinutes($0) }
        )
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
