import SwiftUI

struct ConvertView: View {
    @Environment(RatesStore.self) private var store
    @Environment(\.preferences) private var prefs

    @State private var leftAmount: String = ""
    @State private var rightAmount: String = ""
    @State private var leftCode: String = "RUB"
    @State private var rightCode: String = "USD"
    @State private var activeSide: ConvertSide = .left
    @State private var pickerTarget: PickerTarget?
    @State private var isApplyingProgrammaticUpdate = false
    @FocusState private var focusedSide: ConvertSide?

    private enum PickerTarget: String, Identifiable {
        case left
        case right
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(store.displayDateLine())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        
                        VStack(spacing: 16) {
                            currencyAmountCard(code: leftCode, text: $leftAmount, side: .left) {
                                pickerTarget = .left
                            }

                            Button {
                                swapCurrencies()
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        Circle()
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Поменять валюты местами")

                            currencyAmountCard(code: rightCode, text: $rightAmount, side: .right) {
                                pickerTarget = .right
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                        
                        if let err = store.lastError {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)
                        }
                        
                        Spacer(minLength: 0)
                        
                
                    }
                }
                
                if store.isLoading {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(AppTheme.accent)
                }
            }
            .task {
                await bootstrap()
            }
            .onAppear {
                recalculate(from: activeSide, raw: activeSide == .left ? leftAmount : rightAmount)
            }
            .onChange(of: focusedSide) { _, newValue in
                if let newValue {
                    activeSide = newValue
                }
            }
            .onChange(of: leftAmount) { _, newValue in
                guard activeSide == .left else { return }
                prefs.leftAmountText = newValue
                recalculate(from: .left, raw: newValue)
            }
            .onChange(of: rightAmount) { _, newValue in
                guard activeSide == .right else { return }
                prefs.rightAmountText = newValue
                recalculate(from: .right, raw: newValue)
            }
            .onChange(of: leftCode) { _, _ in
                recalculate(from: activeSide, raw: activeSide == .left ? leftAmount : rightAmount)
            }
            .onChange(of: rightCode) { _, _ in
                recalculate(from: activeSide, raw: activeSide == .left ? leftAmount : rightAmount)
            }
            .onChange(of: store.lastUpdatedISO) { _, _ in
                recalculate(from: activeSide, raw: activeSide == .left ? leftAmount : rightAmount)
            }
            .sheet(item: $pickerTarget) { target in
                CurrencyPickerSheet(
                    currencies: store.currencies,
                    title: target == .left ? "Валюта слева" : "Валюта справа"
                ) { picked in
                    switch target {
                    case .left:
                        leftCode = picked.code
                        prefs.leftCurrencyCode = picked.code
                    case .right:
                        rightCode = picked.code
                        prefs.rightCurrencyCode = picked.code
                    }
                    Task { await store.refresh() }
                    recalculate(from: activeSide, raw: activeSide == .left ? leftAmount : rightAmount)
                }
            }
            .navigationTitle("Конвертер")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Обновить курсы")
                }
            }
        }
        
    }

    private func currencyAmountCard(
        code: String,
        text: Binding<String>,
        side: ConvertSide,
        onSelectCurrency: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(code)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Button(action: onSelectCurrency) {
                    Text("Выбрать валюту")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }
            amountField(text: text, side: side)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }

    private func amountField(text: Binding<String>, side: ConvertSide) -> some View {
        TextField("0", text: text)
            .keyboardType(.decimalPad)
            .font(.title2.monospacedDigit())
            .lineLimit(1)
            .minimumScaleFactor(0.28)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .focused($focusedSide, equals: side)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }

    private func swapCurrencies() {
        swap(&leftCode, &rightCode)
        swap(&leftAmount, &rightAmount)
        prefs.leftCurrencyCode = leftCode
        prefs.rightCurrencyCode = rightCode
        prefs.leftAmountText = leftAmount
        prefs.rightAmountText = rightAmount
        activeSide = activeSide == .left ? .right : .left
        focusedSide = activeSide
        recalculate(from: activeSide, raw: activeSide == .left ? leftAmount : rightAmount)
    }

    private func bootstrap() async {
        leftCode = prefs.leftCurrencyCode
        rightCode = prefs.rightCurrencyCode
        leftAmount = prefs.leftAmountText
        rightAmount = prefs.rightAmountText
        if store.currencies.isEmpty {
            await store.refresh()
        }
        recalculate(from: activeSide, raw: activeSide == .left ? leftAmount : rightAmount)
    }

    private func recalculate(from side: ConvertSide, raw: String) {
        guard !isApplyingProgrammaticUpdate else { return }
        guard let amount = DecimalFormatting.parse(raw) else {
            isApplyingProgrammaticUpdate = true
            if side == .left { rightAmount = "" }
            else { leftAmount = "" }
            isApplyingProgrammaticUpdate = false
            prefs.leftAmountText = leftAmount
            prefs.rightAmountText = rightAmount
            return
        }

        let fromCode = side == .left ? leftCode : rightCode
        let toCode = side == .left ? rightCode : leftCode
        guard let converted = AmountConverter.convert(
            amount: amount,
            from: fromCode,
            to: toCode,
            ratesByCode: store.ratesByCode
        ) else { return }

        isApplyingProgrammaticUpdate = true
        let text = DecimalFormatting.format(converted, fractionDigits: prefs.fractionDigits)
        if side == .left {
            rightAmount = text
        } else {
            leftAmount = text
        }
        isApplyingProgrammaticUpdate = false
        prefs.leftAmountText = leftAmount
        prefs.rightAmountText = rightAmount
    }
}
