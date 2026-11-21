# DroidLink — GitHub & CI/CD Kurulum Kılavuzu

Bu kılavuz, projenin GitHub'da özel (private) bir depoya yüklenmesi ve **GitHub Actions** ile macOS & Android derlemelerinin bulutta otomatik alınması için hazırlanmıştır.

---

## 1. GitHub Özel Deposu Oluşturma

1. GitHub'da `DroidLink` adında **Private** bir repository oluşturun.
2. Yerel deponuzu GitHub deponuza bağlayın:

```bash
git remote add origin https://github.com/<KULLANICI_ADINIZ>/DroidLink.git
git branch -M main
git push -u origin main
```

*(Token kullanacaksanız: `https://<TOKEN>@github.com/<KULLANICI_ADINIZ>/DroidLink.git`)*

---

## 2. GitHub Actions ile macOS Universal Uygulama Derlemesi

Depoya push yaptığınızda `.github/workflows/macos-build.yml` otomatik çalışır:

- **Runner:** `macos-14` (Apple Silicon & Intel uyumlu ortam).
- **Universal Binary:** Hem Intel `x86_64` (Hackintosh i9-13900HX) hem de `arm64` (M1/M2/M3/M4) mimarileri için tek bir fat binary (`lipo`) üretilir.
- **Çıktı (Artifact):** `DroidLink-macOS-Universal.zip`
  - GitHub deponuzdaki **Actions** sekmesinden son workflow'a tıklayarak bu zip dosyasını doğrudan indirebilir ve Mac'inizde `Applications` klasörüne atarak hemen çalıştırabilirsiniz.

---

## 3. GitHub Actions ile Android APK Derlemesi

`.github/workflows/android-build.yml` iş akışı:
- Gradle testlerini koşturur.
- `app-debug.apk` dosyasını derler.
- **Artifact:** `DroidLink-Android-Debug-APK` olarak GitHub'dan indirilmeye hazır sunulur. Telefonunuza doğrudan kurabilirsiniz.
