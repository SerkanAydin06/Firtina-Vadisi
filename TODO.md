# Fırtına Vadisi — yapılacaklar

Yalnızca açık işler tutulur; tamamlananların geçmişi Git/PR kayıtlarındadır.
Öncelik sırasıyla, kullanıcının seçtiği tek madde üzerinde çalış. Liste yeni özellikleri kendiliğinden uygulama yetkisi değildir.
Durum: `[ ]` bekliyor; aktif maddeye “Devam ediyor” ekle. Doğrulanan işi listeden kaldır.

## P1 — yalnızca gerçek cihazda yapılabilecek doğrulamalar

- [ ] **Windows paketini Windows'ta deneme**
  - `build/windows/FirtinaVadisi.exe` Godot 4.6.1 şablonlarıyla derlendi; aynı içerikli Linux paketi editörsüz açılış, rehber, klavye, ayarlar ve ayar kaydı açısından sanal ekranda doğrulandı. Exe'yi gerçek bir Windows makinede aç: tam maç, ses, tam ekran/pencere geçişi ve `%APPDATA%` altındaki ayar kalıcılığı.
- [ ] **Sesleri gerçek çıkışta dinleme**
  - Müzik döngüsünü ve beş olay sesini kulaklık/hoparlörde dinle; geçiş, tıklama ve ses dengesini değerlendir. Mevcut doğrulama teknik sinyal/oynatma testidir.
- [ ] **Gerçek ekranda hızlı göz kontrolü**
  - 1920×1080, 1366×768 ve 1280×720 sanal ekran görüntülerinde taşma yok. Gerçek monitörde ölçekleme (%125/%150 Windows yakınlaştırma) ve pencere modunda konumlanmayı kontrol et.

## P2 — isteğe bağlı iyileştirmeler

- [ ] **Exe simgesi**
  - Pencere simgesi `icon.png` ile ayarlı. Exe dosya simgesi için rcedit kurup Windows ön ayarında `application/modify_resources` ve `.ico` simgeyi etkinleştir.
