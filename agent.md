# 🤖 Agent Guide & Architectural Reference

Bu doküman, **Antigravity Music Player** projesinde çalışacak yapay zeka ajanları (Antigravity / Gemini) ve geliştiriciler için kritik kuralları, ortam yapılandırmasını, mimariyi ve daha önce çözülen kritik sorunları belgeler.

---

## 📌 1. Proje Genel Bakışı

* **Uygulama Adı:** Antigravity Music Player
* **Teknoloji Yığını:** Flutter 3.x, Dart 3.x, C++ (Windows Desktop Runner)
* **Hedef Platform:** Windows Desktop (`.exe`), Web (Chrome)
* **Temel Yetenekler:**
  * Yerel ses dosyalarını (MP3, WAV, FLAC, M4A, Opus, OGG) oynatma.
  * `yt-dlp` ve `ffmpeg` entegrasyonu ile ultra hızlı çok iş parçacıklı (multi-worker) YouTube çalma listesi ve şarkı indirme.
  * Eş zamanlı indirme sayısı seçici (1 - 10 parça aynı anda) ve özel indirme klasörü seçimi.
  * Gerçek 5-Bantlı Grafik Ekolayzer (60 Hz, 230 Hz, 910 Hz, 3.6 kHz, 14 kHz) DSP motoru, 10 hazır ses profili (Düz, Bass Boost, Rap & Hip-Hop, Rock & Metal, Pop, Elektronik, Vokal, Akustik, Klasik, Gece Modu) ve kesintisiz canlı geçiş (hot-swap).
  * Çalma listeleri, Beğenilenler (Favoriler), Geçmiş takibi ve Ayarlar & Ekolayzer merkezi (`SettingsView`).
  * Karışık çalma (Shuffle), Akıllı Tekrar Modları (Off / All / One).
  * Dinamik Çalma Sırası (Play Queue) yönetimi (sürükle-bırak sıralama, bundan sonra çal, sıraya ekle).
  * Oynatma hızı & ses modu ön ayarları (0.5x - 2.0x, Slowed, Nightcore), Stereo Kanal Dengesi (Sol/Sağ).
  * A-B Kesit Tekrarlama (A-B Loop), Uyku Zamanlayıcısı (Sleep Timer) ve Kompakt Mini Oynatıcı (Her Zaman Üstte).
  * Şarkı Bilgileri, ID3 Etiket & Otomatik Şarkı Sözü (LRCLIB Lyrics) bulucu/düzenleyici, Windows Gezgini'nde dosya konumunu gösterme.
  * M3U / M3U8 çalma listesi içe ve dışa aktarma, Kütüphane gruplama (Sanatçılar, Albümler/Klasörler, En Çok Dinlenenler), kütüphane bakım/onarım aracı ve masaüstü klavye kısayolları.
  * SharedPreferences tabanlı kalıcı veri ve son oturum (kuyruk/aktif şarkı) yönetimi.

---

## ⚡ 2. Kritik Windows Geliştirme ve Derleme Kuralları

### A. Dizin ve Junction Yolu (`C:\MuzikPlayer`)
* **Sorun:** Fiziksel çalışma alanı yolu (`C:\Users\METIN\Desktop\Muzik Uygulaması\Antigravity`) Türkçe karakter (`ı`) ve boşluk içerir. CMake ve Windows C++ derleyicisi bu yolda derleme yaparken hata verebilir.
* **Kural:** Windows Masaüstü derlemeleri daima junction dizini olan **`C:\MuzikPlayer`** üzerinden çalıştırılmalıdır:
  ```powershell
  Set-Location C:\MuzikPlayer
  & "C:\flutter\bin\flutter.bat" build windows
  ```

### B. Çalışan Sürecin Kilitlenmesi (Process Locking)
* Derleme yapmadan önce mutlaka çalışan `antigravity_music.exe` sürecini sonlandırın; aksi takdirde `.exe` dosyası kilitli olduğu için derleme `Access Denied` hatası verir:
  ```powershell
  Stop-Process -Name "antigravity_music" -Force -ErrorAction SilentlyContinue
  ```

### C. Statik Kod Analizi
* Her değişiklikten sonra mutlaka statik analiz çalıştırın:
  ```powershell
  & "C:\flutter\bin\flutter.bat" analyze lib
  ```

---

## 🏗️ 3. Proje Mimarisi (MVVM)

```text
lib/
├── models/
│   ├── track.dart                  # Şarkı veri modeli, Mojibake düzeltici
│   ├── playlist.dart               # Çalma listesi modeli
│   └── download_item.dart          # İndirme ilerlemesi, durumlar ve ham loglar
├── services/
│   ├── audio_player_service.dart   # audioplayers ses motoru & 5-Bant FFmpeg Ekolayzer DSP
│   ├── file_picker_service.dart    # Yerel dosya seçici, klasör tarayıcı & M3U içe/dışa aktarıcı
│   ├── online_music_service.dart   # yt-dlp & YouTube Explode indirme + LRCLIB şarkı sözü motoru
│   └── storage_service.dart        # SharedPreferences kalıcı JSON & ayar kayıtları
├── viewmodels/
│   └── player_viewmodel.dart       # Merkezi ChangeNotifier durum yöneticisi
└── ui/
    ├── theme/
    │   └── app_theme.dart          # Koyu tema renkleri ve stilleri
    ├── widgets/
    │   ├── player_bottom_bar.dart  # Sabit alt oynatıcı paneli, EQ & ses efektleri
    │   ├── sidebar_navigation.dart # Masaüstü kenar menüsü (0..5 indeksleri)
    │   ├── track_list_item.dart    # Şarkı kartı ve bağlam menüsü
    │   ├── audio_visualizer.dart   # Animasyonlu ses dalgası
    │   └── import_to_playlist_dialog.dart # Dosyaları listeye ekleme diyaloğu
    └── views/
        ├── home_view.dart          # Ana sayfa düzeni & klavye kısayolları
        ├── library_view.dart       # 0: Yerel müzik kütüphanesi
        ├── search_online_view.dart # 1: YouTube çalma listesi indirme
        ├── favorites_view.dart     # 2: Beğenilenler
        ├── playlists_view.dart     # 3: Çalma listeleri görünümü
        ├── history_view.dart       # 4: Son çalınanlar
        └── settings_view.dart      # 5: 5-Bant Ekolayzer, İndirme & Sistem Ayarları
```

### Navigasyon İndeksleri (`HomeView` & `SidebarNavigation`)
* `0`: `LibraryView` (Kütüphanem)
* `1`: `SearchOnlineView` (Çalma Listesi İndir)
* `2`: `FavoritesView` (Beğenilenler)
* `3`: `PlaylistsView` (Çalma Listeleri)
* `4`: `HistoryView` (Son Çalınanlar)
* `5`: `SettingsView` (Ayarlar & Ekolayzer)

### 5-Bant Grafik Ekolayzer DSP & Ayarlar (`SettingsView`)
* `AudioPlayerService`, FFmpeg `equalizer` filtre zinciri (`60 Hz, 230 Hz, 910 Hz, 3.6 kHz, 14 kHz`) ve otomatik anti-clipping preamp (`volume`) ile gerçek ses işleme uygular.
* Ekolayzer bandı veya ön ayarı (`flat`, `bass_boost`, `rap`, `rock`, `pop`, `electronic`, `vocal`, `acoustic`, `classical`, `night`, `custom`) değiştirildiğinde aktif şarkı mevcut saniyesi korunarak (`hotSwap`) kesintisiz güncellenir.
* `SettingsView` üzerinden Ekolayzer & Ses DSP, YouTube İndirme Motoru ayarları, Kütüphane Bakım/Onarım (`runLibraryMaintenance`), Önbellek Temizleme (`clearAudioCache`) ve Harici Motor (`ffmpeg` / `yt-dlp`) sağlık kontrolleri yönetilir.

---

## 🛡️ 4. Kritik Kodlama İlkeleri ve Tecrübeler

### 1. Türkçe Mojibake (Karakter Bozulması) Önleme
* `Track.fixMojibake(String)` fonksiyonu hem yerel dosya adlarında hem de YouTube API çıktılarında `ISO-8859-1` / `Windows-1254` kaynaklı bozuk karakterleri (`Ä±`, `Ã§`, `Ã¶` vb.) temizler.
* Yeni bir başlık, albüm adı veya sanatçı adı işlerken mutlaka `Track.fixMojibake` çağrılmalıdır.
* `yt-dlp` işlemlerinde daima şu çevre değişkenleri tanımlanmalıdır:
  ```dart
  environment: {
    'PYTHONIOENCODING': 'utf-8',
    'PYTHONUTF8': '1',
  }
  ```

### 2. Dize Parçalama (Substring) ve `RangeError` Güvenliği
* **Hata Geçmişi:** `file.path.lastIndexOf('.')` sonucu elde edilen indeks (örn: 70), sadece dosya adı olan `base` (33 karakter) değişkeninde `base.substring(0, dot)` şeklinde çalıştırıldığında `RangeError (end): 0..33: 70` çökmesine yol açmıştı.
* **Kural:** Dosya adından uzantı ayıklarken `dot` indeksi **daima sadece dosya adı üzerinden** (`base.lastIndexOf('.')`) hesaplanmalıdır.
* Tüm `substring` çağrılarında üst sınır `math.min(targetIndex, string.length)` veya `.clamp(0, length)` ile korunmalıdır.

### 3. YouTube `NA` Başlıkları ve Silinmiş İçerikler
* YouTube üzerinde silinmiş veya telif nedeniyle engellenmiş parçaların başlığı `yt-dlp` tarafından `"NA"` döner.
* `_looseMatch` fonksiyonu `"NA"` ifadesini asla eşleştirmemeli ve en az 4 karakterlik belirteçler aramalıdır.
* Listedeki adı `"NA"` olan parçalar kullanıcıya `Kaldırılmış / Kısıtlanmış Video (VideoID)` olarak gösterilmelidir.

### 4. Şeffaf Hata Çıktısı ve Ham Terminal Logları
* İndirme başarısızlıklarında hatalar Türkçeleştirilerek veya basitleştirilerek gizlenmemelidir.
* Kullanıcıya doğrudan `yt-dlp`'nin ürettiği ham `ERROR:` satırı sunulmalı; ayrıca `[>_ Terminal Logu]` butonuyla sürecin ürettiği tüm `stderr` ve `stdout` çıktıları incelenebilir olmalıdır.

### 5. Karışık Çalma (Shuffle) Mantığı
* Karışık çalma butonu `assets/icons/shuffle.png` özel vektör/PNG ikonunu kullanır.
* Shuffle açıldığında aktif şarkı sırası rastgele karıştırılır; kapatıldığında orijinal liste sırasına geri dönülür.

### 6. Alt Ajan (Subagent) Kullanımı ve Regresyon Koruması
* Tüm işleri tek başına ana ajan üzerinde yapmak yerine görevleri paralel **alt ajanlara (`code-reviewer`, `test-engineer`, `research`, `self`)** delege edin.
* Her yeni özellik eklendikten sonra mutlaka `code-reviewer` ve `test-engineer` alt ajanlarını başlatarak **eski özelliklerin (YouTube çoklu indirme, ham terminal logları, Mojibake düzeltici, yerel dosya içe aktarma, çalma listesi yönlendirmeleri vb.) bozulmadığını (regresyon olmadığını)** doğrulayın.

---

## 🛠️ 5. Sık Kullanılan Komutlar

```powershell
# Bağımlılıkları kontrol et
flutter pub get

# Statik analiz (Sıfır hata olmalı)
flutter analyze lib

# Windows için Release derlemesi
Set-Location C:\MuzikPlayer
flutter build windows

# Derlenen uygulamayı başlat
Start-Process "C:\MuzikPlayer\build\windows\x64\runner\Release\antigravity_music.exe"
```
