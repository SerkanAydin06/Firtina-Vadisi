# Fırtına Vadisi — yapılacaklar

Yalnızca açık işler tutulur; tamamlananların geçmişi Git/PR kayıtlarındadır.
Öncelik sırasıyla, kullanıcının seçtiği tek madde üzerinde çalış. Liste yeni özellikleri kendiliğinden uygulama yetkisi değildir.
Durum: `[ ]` bekliyor; aktif maddeye “Devam ediyor” ekle. Doğrulanan işi listeden kaldır.

## P1 — kalan doğrulamalar ve teknik eksikler

- [ ] **Editör testinin temiz kapanması**
  - `tests/editor_preview.gd` için Godot 4.6 `--editor --script` kapanışındaki RID/kaynak uyarılarının nedenini ayır ve test yaşam döngüsünü düzelt. Uyarıları gizleme; ayarlara dokunmama ve düğüm çoğaltmama kontrollerini koru.
- [ ] **Sesleri gerçek çıkışta dinleme**
  - Müzik döngüsünü ve beş olay sesini kulaklık/hoparlörde dinle; geçiş, tıklama ve ses dengesini değerlendir. Mevcut doğrulama teknik sinyal/oynatma testidir; dinleme tamamlanmış sayılmasın.
- [ ] **Farklı ekranlarda kullanım kontrolü**
  - 1920×1080, 1366×768 ve 1280×720'de pencere/tam ekran; ayarlar, araç ipuçları ve sonuç panelini kontrol et. Metin taşması, küçük tıklama alanı veya klavye odağı sorunu bulunursa düzelt.

## P2 — kullanım kolaylığı

- [ ] **Maçı terk etmeden ayarlar**
  - Oyun içinden ses, hareketi azalt ve bekleme ayarlarına erişim ekle. Açık panel arkadaki girdiyi engellesin; maçı sıfırlamasın, devam eden turla çakışmasın.
- [ ] **Kısa oyun içi rehber**
  - Üç komut → rüzgâr → kontrat → teslimat akışını ve çapanın tek rüzgâr etkisini anlatan, kapatılabilir bir rehber ekle. Menüden yeniden açılabilsin.

## P3 — paylaşılabilir sürüm

- [ ] **Windows dışa aktarma ve paket kontrolü**
  - Depoda dışa aktarma önayarı yok. Windows önayarı ve kısa paketleme yönergesi ekle; paketi Godot editörü olmayan ortamda açılış, tam maç, ses ve ayar kalıcılığı açısından doğrula.
- [ ] **Tanıtım ve kullanım belgelerini güncelleme**
  - README'deki ayarlar/test kapsamını güncelle; güncel oyun, zafer ve ayarlar ekranlarını ekle. Kullanılan Godot sürümü ile test edilen sürümleri açıkça belirt.
