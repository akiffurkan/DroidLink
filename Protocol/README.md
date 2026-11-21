# DroidLink Protokol Spesifikasyonu (v1.0.0)

Bu doküman macOS (Intel & Apple Silicon) ve Android (Samsung Galaxy A04e vb.) arasındaki DroidLink iletişim protokolünü tanımlar.

## 1. Ağ Portları ve Keşif
- **mDNS Service Type:** `_droidlink._tcp.local.`
- **WebSocket Kontrol Portu:** `8765` (varsayılan)
- **HTTP Dosya Transfer Portu:** `8766` (varsayılan)

## 2. Ortak Mesaj Formatı

Tüm mesajlar aşağıdaki temel zarf (envelope) yapısına sahiptir:

```json
{
  "protocolVersion": 1,
  "messageId": "uuid-v4",
  "type": "BATTERY_UPDATE | PAIR_REQUEST | PAIR_RESPONSE | FILE_LIST_REQ | FILE_LIST_RESP | FILE_TRANSFER_INIT | FILE_CHUNK | FILE_TRANSFER_COMPLETE | HEARTBEAT",
  "timestamp": 1711050000000,
  "payload": {}
}
```

## 3. Pil Mesajı (`BATTERY_UPDATE`)

```json
{
  "protocolVersion": 1,
  "messageId": "550e8400-e29b-41d4-a716-446655440000",
  "type": "BATTERY_UPDATE",
  "timestamp": 1711050000000,
  "payload": {
    "deviceId": "samsung-sm-a042f-uuid",
    "deviceName": "Galaxy A04e",
    "batteryLevel": 84,
    "isCharging": true,
    "chargingSource": "usb",
    "temperature": 29.5,
    "health": "GOOD",
    "voltage": 4120
  }
}
```

- `batteryLevel`: 0 - 100 arası tam sayı.
- `isCharging`: true / false.
- `chargingSource`: `"none"`, `"ac"`, `"usb"`, `"wireless"`.
- `temperature`: Santigrat derece (float) veya null.
- `health`: `"GOOD"`, `"OVERHEAT"`, `"DEAD"`, `"OVER_VOLTAGE"`, `"UNKNOWN"`.
- `voltage`: Milivolt (mV) tam sayı veya null.
