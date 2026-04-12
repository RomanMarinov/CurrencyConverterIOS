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
                            Task {
                                await DailyReminderService.reschedule()
                                await MainActor.run { refreshReminderStatus() }
                            }
                        }

                    DatePicker(
                        "Время",
                        selection: $reminderTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .disabled(!reminderOn)
                    .onChange(of: reminderTime) { _, newValue in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        if let h = c.hour { DailyReminderService.hour = h }
                        if let m = c.minute { DailyReminderService.minute = m }
                        Task {
                            await DailyReminderService.reschedule()
                            await MainActor.run { refreshReminderStatus() }
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
                    Text("Локальное уведомление: откройте приложение и обновите курсы. Фоновое автообновление iOS не гарантирует сеть в момент срабатывания.")
                }

                Section("Источник данных") {
                    Link("ЦБ РФ — daily JSON (бесплатно)", destination: URL(string: "https://www.cbr-xml-daily.ru/")!)
                    Text("Котировки — официальные курсы Банка России. Рубль не приходит отдельной строкой в JSON, поэтому в приложении он задан как база с курсом 1 ₽ — без второго API.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
            refreshReminderStatus()
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func refreshReminderStatus() {
        guard reminderOn else {
            reminderStatus = ""
            return
        }
        reminderStatus = "Напоминание: \(Self.timeString(hour: DailyReminderService.hour, minute: DailyReminderService.minute))"
    }

    private static func makeTime(hour: Int, minute: Int) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = hour
        c.minute = minute
        return Calendar.current.date(from: c) ?? Date()
    }

    private static func timeString(hour: Int, minute: Int) -> String {
        let d = makeTime(hour: hour, minute: minute)
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: d)
    }
}
