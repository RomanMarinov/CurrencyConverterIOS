import SwiftUI

struct SettingsView: View {
    @Environment(\.preferences) private var prefs

    @State private var fractionDigits: Double = 2
    @State private var reminderOn = false
    @State private var reminderTime = Date()
    @State private var reminderStatus = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Отображение") {
                    Stepper(value: $fractionDigits, in: 1 ... 6, step: 1) {
                        Text("Знаков после запятой: \(Int(fractionDigits))")
                    }
                    .onChange(of: fractionDigits) { _, newValue in
                        prefs.fractionDigits = Int(newValue)
                    }
                }

                Section {
                    Toggle("Ежедневное напоминание", isOn: $reminderOn)
                        .onChange(of: reminderOn) { _, on in
                            DailyReminderService.isEnabled = on
                            if on {
                                DailyReminderService.persistTime(from: reminderTime)
                            }
                            Task {
                                await DailyReminderService.reschedule()
                                await refreshReminderStatus()
                            }
                        }

                    DatePicker(
                        "Время",
                        selection: $reminderTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .disabled(!reminderOn)
                    .onChange(of: reminderTime) { _, newValue in
                        DailyReminderService.persistTime(from: newValue)
                        Task {
                            await DailyReminderService.reschedule()
                            await refreshReminderStatus()
                        }
                    }

                    if !reminderStatus.isEmpty {
                        Text(reminderStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Напоминания")
                } footer: {
                    Text("Локальное уведомление в выбранное время. Если приложение открыто — покажется баннер и курсы обновятся. В фоне iOS не гарантирует сеть без открытия приложения.")
                }

                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
        }
        .onAppear {
            fractionDigits = Double(prefs.fractionDigits)
            reminderOn = DailyReminderService.isEnabled
            reminderTime = Self.makeTime(hour: DailyReminderService.hour, minute: DailyReminderService.minute)
            Task {
                await refreshReminderStatus()
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    @MainActor
    private func refreshReminderStatus() async {
        guard reminderOn else {
            reminderStatus = ""
            return
        }
        reminderStatus = await DailyReminderService.statusMessage()
    }

    private static func makeTime(hour: Int, minute: Int) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = hour
        c.minute = minute
        return Calendar.current.date(from: c) ?? Date()
    }
}
