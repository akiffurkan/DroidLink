# DroidLink

DroidLink, **macOS (Intel & Apple Silicon)** ile **Samsung Galaxy A04e (Android / One UI Core)** arasında yüksek hızlı, düşük gecikmeli ve güvenli yerel ağ entegrasyonu sağlayan modern bir ekosistemdir.

---

## Özellikler

- **Menü Çubuğu Pil Göstergesi:** macOS menü çubuğunda telefonun pil yüzdesini ve şarj durumunu anlık canlı gösterir (`DroidLink · 84% ⚡`).
- **Liquid Glass Detay Paneli:** Transparan popover ile pil seviyesi, sıcaklık, voltaj, şarj kaynağı (AC/USB) ve bağlantı durumu.
- **Yerel Ağ Keşfi (mDNS / Bonjour):** IP adresi girmeye gerek kalmadan `_droidlink._tcp` ile otomatik cihaz bulma.
- **Çift Kanallı İletişim:** Kontrol ve pil verileri için WebSocket (Port 8765), dosya aktarımı için HTTP Stream (Port 8766).
- **Dosya Transferi Hazırlığı:** Scoped Storage (SAF) uyumlu, chunked ve SHA-256 bütünlük kontrollü aktarım altyapısı.
- **Intel Mac & Apple Silicon Uyumluluğu:** Intel Core i9-13900HX Hackintosh ve Apple Silicon cihazlarda yerel (native) performans.

---

## Proje Yapısı

```
DroidLink/
├── macOS/                          # macOS SwiftUI / AppKit Menü Çubuğu Uygulaması
│   ├── Package.swift               # Swift Package Manager Tanımı (macOS 13+)
│   ├── Sources/
│   │   ├── App/                    # DroidLinkApp.swift (Menü bar accessory başlatıcı)
│   │   ├── MenuBar/                # MenuBarController.swift (NSStatusItem & NSPopover)
│   │   ├── Views/                  # BatteryDetailPopoverView, FileTransferView
│   │   ├── ViewModels/             # BatteryViewModel.swift
│   │   ├── Networking/             # BonjourDiscovery.swift, WebSocketClient.swift
│   │   └── Models/                 # BatteryInfo, ProtocolMessage, Device, TransferItem
│   └── Tests/                      # Swift Birim Testleri
│
├── Android/                        # Android Companion Uygulaması (Samsung Galaxy A04e)
│   ├── app/
│   │   ├── src/main/java/com/droidlink/
│   │   │   ├── MainActivity.kt
│   │   │   ├── DroidLinkApplication.kt
│   │   │   ├── battery/            # BatteryMonitor.kt (ACTION_BATTERY_CHANGED dinleyici)
│   │   │   ├── service/            # DroidLinkForegroundService.kt
│   │   │   ├── networking/         # DroidWebSocketServer.kt, NsdHelper.kt (mDNS)
│   │   │   ├── models/             # BatteryPayload, DroidMessage
│   │   │   └── ui/                 # Jetpack Compose ekranları
│   │   └── AndroidManifest.xml
│   ├── build.gradle.kts
│   └── settings.gradle.kts
│
├── Protocol/                       # Ortak İletişim Protokolü & JSON Şemaları
│   ├── schemas/                    # battery_message.json, pairing_message.json, transfer_message.json
│   └── README.md
│
└── README.md
```

---

## Derleme ve Çalıştırma

### 1. macOS Uygulaması
macOS terminalinde (Hackintosh Intel Core i9-13900HX veya Apple Silicon):
```bash
cd macOS
swift build -c release
# veya doğrudan çalıştırmak için:
swift run
```
Xcode ile açmak için:
```bash
open macOS/Package.swift
```

### 2. Android Uygulaması (Samsung Galaxy A04e)
Android Studio ile `Android/` klasörünü açın veya komut satırından derleyin:
```bash
cd Android
./gradlew assembleDebug
```
Üretilen APK (`app/build/outputs/apk/debug/app-debug.apk`) Samsung Galaxy A04e cihazına yüklenir.
- Android uygulamasında **"Servisi Başlat"** butonuna basıldığında WebSocket sunucusu açılır ve mDNS servisi yayına başlar.
- macOS menü çubuğundaki DroidLink uygulaması telefonu otomatik olarak yakalar ve canlı pil seviyesini menü çubuğuna yansıtır.
