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
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                VStack(alignment: .leading, spacing: 12) {
                    Text(store.displayDateLine())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                    HStack(alignment: .firstTextBaseline) {
                        amountField(text: $leftAmount, side: .left)
                        Spacer(minLength: 16)
                        amountField(text: $rightAmount, side: .right)
                    }
                    .padding(.horizontal, 12)

                    HStack {
                        Text(leftCode)
                            .font(.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            swapCurrencies()
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.title3)
                                .foregroundStyle(AppTheme.accent)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                        Text(rightCode)
                            .font(.title)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 16) {
                        selectCard(title: "Выбрать валюту", code: leftCode) {
                            pickerTarget = .left
                        }
                        selectCard(title: "Выбрать валюту", code: rightCode) {
                            pickerTarget = .right
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

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
    }

    private var headerBar: some View {
        ZStack {
            Rectangle()
                .fill(AppTheme.headerFill)
                .frame(height: 50)
            Text("Конвертер валют")
                .font(.subheadline.weight(.semibold))
            HStack {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                .padding(.leading, 8)
                Spacer()
            }
        }
    }

    private func amountField(text: Binding<String>, side: ConvertSide) -> some View {
        TextField("0", text: text)
            .keyboardType(.decimalPad)
            .font(.title2)
            .multilineTextAlignment(side == .left ? .leading : .trailing)
            .frame(maxWidth: .infinity, alignment: side == .left ? .leading : .trailing)
            .focused($focusedSide, equals: side)
    }

    private func selectCard(title: String, code: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.accent)
                    .multilineTextAlignment(.center)
                Text(code)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
