# 🎵 Antigravity Music Player

Modern, şık ve güçlü hibrit müzik çalar uygulaması. Hem bilgisayarınızdaki yerel müzik dosyalarını (MP3, WAV, FLAC, M4A vb.) çalabilir hem de YouTube ve çevrim içi müzik akışlarını arayıp kesintisiz dinlemenizi sağlar.

---

## ✨ Özellikler

- **🎧 Hibrit Oynatma Desteği:**
  - **Yerel Dosyalar:** Tek tek dosya seçme veya bütün bir müzik klasörünü tek tıkla tarayıp kütüphaneye ekleme.
  - **Çevrim İçi Müzik (YouTube):** Herhangi bir API anahtarı gerekmeden doğrudan YouTube üzerinden şarkı arama ve dinleme.
  - **Öne Çıkan Akışlar:** Lofi Study Beats, Chillout, Cyberpunk Synthwave, Gece Cazı gibi anında dinlemeye hazır istasyonlar.

- **🎛️ Gelişmiş Oynatıcı Kontrolleri:**
  - Oynat / Duraklat / Sonraki / Önceki parça.
  - Etkileşimli zaman çubuğu (Seekbar) ile anlık süre takibi.
  - Karışık Çalma (Shuffle) ve Akıllı Tekrar Modları (Kapalı / Tüm Liste / Tek Parça).
  - Ses seviyesi ayarlayıcı ve tek tıkla sessize alma (Mute).
  - Canlı hareketli ses dalgası görselleştiricisi (Audio Visualizer).

- **📂 Çalma Listeleri & Favoriler:**
  - Özel çalma listeleri oluşturma, listelere şarkı ekleme/çıkarma.
  - Beğenilen şarkıları favorilere ekleme ve tek tıkla tüm favorileri çalma.
  - Son çalınan şarkıların otomatik geçmiş takibi.

- **💾 Kalıcı Veri (Persistence):**
  - Eklediğiniz şarkılar, favorileriniz, özel çalma listeleriniz ve ses ayarlarınız `shared_preferences` ile kaydedilir; uygulama kapatılıp açıldığında korunur.

- **🎨 Modern Material 3 UI:**
  - Koyu tema (Dark Obsidian & Neon Violet/Cyan).
  - Masaüstü için kenar çubuğu (Sidebar), mobil ve dar ekranlar için duyarlı alt menü.

---

## 🚀 Uygulamayı Çalıştırma

### 1. Web / Chrome Üzerinde Hızlı Başlatma (Hemen Kullanıma Hazır):
Terminalde veya PowerShell'de:
```powershell
flutter run -d chrome
```
veya doğrudan hazırladığımız betiği çalıştırabilirsiniz:
```powershell
.\run_web.ps1
```

### 2. Windows Masaüstü Yerel (Native .exe) Olarak Çalıştırma:
Windows yerel masaüstü uygulaması olarak derlemek için sisteminizde Visual Studio C++ Derleme Araçları gereklidir.
Eğer yüklü değilse PowerShell yönetici penceresinden:
```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override "--passive --add Microsoft.VisualStudio.Workload.VCTools"
```
Ardından:
```powershell
flutter run -d windows
```

---

## 📁 Proje Mimarisi

```text
lib/
├── models/
│   ├── track.dart                  # Şarkı modeli (Yerel & Çevrim İçi)
│   └── playlist.dart               # Çalma listesi modeli
├── services/
│   ├── audio_player_service.dart   # audioplayers motoru ve olayları
│   ├── file_picker_service.dart    # Dosya ve klasör tarama servisi
│   ├── online_music_service.dart   # YouTube Explode & hazır akış servisleri
│   └── storage_service.dart        # Kalıcı kayıt (SharedPreferences)
├── viewmodels/
│   └── player_viewmodel.dart       # MVVM State yönetimi (ChangeNotifier)
└── ui/
    ├── theme/
    │   └── app_theme.dart          # Koyu tema & renk paleti
    ├── widgets/
    │   ├── player_bottom_bar.dart  # Sabit alt oynatıcı paneli
    │   ├── sidebar_navigation.dart # Masaüstü kenar gezinti çubuğu
    │   ├── track_list_item.dart    # Şarkı kartı & bağlam menüsü
    │   ├── audio_visualizer.dart   # Animasyonlu ses dalgası
    │   └── add_to_playlist_dialog.dart # Çalma listesine ekleme diyaloğu
    └── views/
        ├── home_view.dart          # Ana sayfa düzeni
        ├── library_view.dart       # Yerel müzik kütüphanesi
        ├── search_online_view.dart # Çevrim içi müzik arama & keşfet
        ├── playlists_view.dart     # Çalma listeleri görünümü
        ├── favorites_view.dart     # Beğenilenler
        └── history_view.dart       # Son çalınanlar
```
