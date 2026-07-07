# CurrencyConverter — iOS

[![Swift 5](https://img.shields.io/badge/Swift-5.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-007AFF?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![iOS 18+](https://img.shields.io/badge/iOS-18%2B-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![ЦБ РФ API](https://img.shields.io/badge/ЦБ%20РФ-daily__json-2E7D32?style=flat-square)](https://www.cbr-xml-daily.ru/)

## Требования к сборке

[![Xcode 16+](https://img.shields.io/badge/Xcode-16%2B-147EFB?style=flat-square&logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)&nbsp;
[![iOS Deployment Target 18.0](https://img.shields.io/badge/Deployment%20Target-18.0-555555?style=flat-square)](https://developer.apple.com/documentation/xcode/configuring-your-project-for-ios)

- macOS с установленным **Xcode 16+**
- Симулятор или устройство с **iOS 18.0+**
- Для CI на GitHub Actions используется runner `macos-15` и симулятор **iPhone 16**

## Возможности

`CurrencyConverter` — нативное **iOS**-приложение на **SwiftUI** для конвертации валют по официальным курсам **Центрального банка РФ**. Курсы загружаются из публичного API [`cbr-xml-daily.ru`](https://www.cbr-xml-daily.ru/daily_json.js); пересчёт выполняется через рубль как базовую валюту.

Приложение поддерживает 3 основных экрана:

- **Конвертер** — двусторонний ввод суммы, выбор валют, обмен местами, обновление курсов
- **Курсы ЦБ** — список валют с поиском, pull-to-refresh и датой котировок
- **Настройки** — точность отображения (1–6 знаков после запятой), ежедневное локальное напоминание

Дополнительно:

- сохранение выбранных валют и введённых сумм в `UserDefaults`
- локальное уведомление с напоминанием обновить курсы (без фоновой загрузки по расписанию)

## Архитектура слоёв

Проект следует **Clean Architecture**: домен не зависит от UI и сети, зависимости собираются в composition root.

| Слой / папка | Назначение |
|--------------|------------|
| `Core/Domain` | Сущности (`CurrencyRate`, `ExchangeRatesSnapshot`), use cases, протокол `ExchangeRatesRepository` |
| `Core/Data/CBR` | `CBRExchangeRatesRepository` — HTTP-запрос и парсинг JSON ЦБ РФ |
| `Core/Stores` | `RatesStore` — UI-состояние курсов, загрузка и делегирование конвертации |
| `Core/Preferences` | `UserPreferences` — настройки и последние значения конвертера |
| `Core/Notifications` | `DailyReminderService` — локальные уведомления через `UserNotifications` |
| `Composition` | `AppCompositionRoot` — единственная точка сборки зависимостей |
| `UI` | SwiftUI-экраны: `ConvertView`, `RatesListView`, `SettingsView`, `RootTabView` |

## Сценарии работы

### Загрузка курсов

`RatesStore.refresh() -> FetchExchangeRatesUseCase -> CBRExchangeRatesRepository -> GET daily_json.js -> ExchangeRatesSnapshot`

Репозиторий:

- запрашивает `https://www.cbr-xml-daily.ru/daily_json.js`
- нормализует номинал и значение каждой валюты в `rubPerUnit`
- добавляет базовую валюту `RUB` и сортирует список по названию

### Конвертация суммы

`ввод в активном поле -> DecimalFormatting.parse -> ConvertCurrencyAmountUseCase -> пересчёт через RUB -> форматирование результата`

Формула в домене:

```text
rubAmount = amount × from.rubPerUnit
result    = rubAmount ÷ to.rubPerUnit
```

Активная сторона ввода (`ConvertSide`) определяет, какое поле является источником пересчёта.

### Напоминания

`включение в Настройках -> запрос разрешения UNUserNotificationCenter -> UNCalendarNotificationTrigger (ежедневно)`

Уведомление напоминает открыть приложение и обновить курсы; фоновое автообновление iOS не гарантирует сеть в момент срабатывания.

## Источник данных

| Поле / сущность | Назначение |
|-----------------|------------|
| `ExchangeRatesSnapshot.dateISO8601` | дата котировок ЦБ |
| `CurrencyRate.code` | ISO-код валюты (`USD`, `EUR`, …) |
| `CurrencyRate.name` | название валюты |
| `CurrencyRate.rubPerUnit` | стоимость 1 единицы валюты в рублях |

Внешний API не требует ключа; для работы конвертера нужен доступ в интернет при обновлении курсов.

## Структура проекта

```text
CurrencyConverter/
├── CurrencyConverter/          # исходники приложения
│   ├── Core/
│   ├── UI/
│   ├── Composition/
│   └── Design/
├── CurrencyConverterTests/     # unit-тесты
├── CurrencyConverterUITests/   # UI-тесты
└── .github/workflows/ios-ci.yml
```

## Unit-тесты

В проекте настроены unit-тесты доменной логики:

- `testConversionThroughRubBaseline` — пересчёт через рубль (`ConvertCurrencyAmountUseCase`)

Локальный запуск тестов:

```bash
xcodebuild test \
  -project CurrencyConverter.xcodeproj \
  -scheme CurrencyConverter \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:CurrencyConverterTests \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO
```

## CI/CD

В репозитории настроен **GitHub Actions** — workflow [`.github/workflows/ios-ci.yml`](.github/workflows/ios-ci.yml).

### Триггеры запуска

Workflow запускается автоматически при:

- **Push** в ветки: `main`, `dev`
- **Pull Request** в ветки: `main`, `dev`

### Что проверяется

| Платформа | Runner | Задачи |
|-----------|--------|--------|
| **iOS** | `macos-15` | Сборка Debug для симулятора (`xcodebuild build`), unit-тесты (`CurrencyConverterTests` на `iPhone 16`) |

### Статус сборки

[![iOS CI](https://github.com/RomanMarinov/CurrencyConverterIOS/actions/workflows/ios-ci.yml/badge.svg)](https://github.com/RomanMarinov/CurrencyConverterIOS/actions/workflows/ios-ci.yml)

### Локальный запуск CI-команд

```bash
# Сборка
xcodebuild build \
  -project CurrencyConverter.xcodeproj \
  -scheme CurrencyConverter \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO

# Unit-тесты
xcodebuild test \
  -project CurrencyConverter.xcodeproj \
  -scheme CurrencyConverter \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:CurrencyConverterTests \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO
```

## Локальный запуск

1. Откройте `CurrencyConverter.xcodeproj` в Xcode.
2. Выберите схему **CurrencyConverter** и симулятор или устройство с iOS 18+.
3. Запустите проект (**⌘R**).

Для напоминаний на реальном устройстве разрешите уведомления при первом включении опции в **Настройках**.

## Лицензия

Проект распространяется без отдельного файла лицензии. При публикации на GitHub добавьте `LICENSE` по вашему выбору.
