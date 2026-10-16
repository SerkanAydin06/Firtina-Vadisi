# Fırtına Vadisi — yapılacaklar

Yalnızca açık işler tutulur; tamamlananların geçmişi Git/PR kayıtlarındadır.
Öncelik sırasıyla, kullanıcının seçtiği tek madde üzerinde çalış. Liste yeni özellikleri kendiliğinden uygulama yetkisi değildir.
Durum: `[ ]` bekliyor; aktif maddeye “Devam ediyor” ekle. Doğrulanan işi listeden kaldır.
“Karar gerekiyor” etiketli maddeler kural/denge değişikliğidir; kullanıcı onayı olmadan uygulanmaz.

## P1 — hatalar ve kalan doğrulamalar

- [ ] **Botların rüzgâr yüzünden tur boyu kilitlenmesi**
  - `_ai_next_command` her geçişte o turun rüzgârını uygular ve duvara/kayaya değen her rotayı imkânsız sayar; hiçbir rota bulamayınca üç komutun hepsi Çapa olur. Botlar-arası 8 maçlık simülasyonda bot turlarının yaklaşık %10–25'i bu şekilde boş geçti.
  - Örnekler: (0,0)'da güneye bakan pilot + batı rüzgârı → tek çıkış Çapa (ilk turda da olur); (8,6)–(9,8) bölgesi + güney rüzgârı → tuzak.
  - Düzeltme: aramayı maliyetli yap (1 gövde kaybını yüksek maliyetle kabul et, can 1 iken etme); hedefe ulaşılamıyorsa hedefe en yakın güvenli konumu seç. Kabul: aynı senaryolarda bot hareket ediyor, regresyon testi eklendi, simülasyonda tam-Çapa turu belirgin şekilde azaldı.
- [ ] **Tur çözülürken “Yeni Oyun” sessizce çalışmıyor**
  - `_on_restart_pressed` çözüm sırasında hiçbir şey yapmıyor ama düğme etkin görünüyor; “Ana Menü” ise aynı anda turu iptal edebiliyor. İkisini tutarlı yap: ya çözüm sırasında Yeni Oyun da güvenle iptal edip yeni maç açsın ya da düğme devre dışı görünsün.
- [ ] **Klavye kontrolleri**
  - Projede hiç `_input`/kısayol yok. Ekle: 1–6 komut seçimi, Enter programı çalıştır, Backspace son komutu kaldır, Esc ayarlar panelini/sonuç ekranını kapatsın. Seçili slotu kaldırma şu an yalnızca fareyle mümkün; odaklanabilir yap. Kısayollar çözüm sırasında ve zafer ekranında girdi kilidine uysun.
- [ ] **Pencere boyutu küçük ekranlarda taşabilir**
  - `project.godot` pencere geçersiz kılmasını 1920×1080'e sabitliyor; Ayarlar'dan pencere moduna geçince 1366×768 / 1280×720 ekranlarda pencere ekrandan büyük açılabilir. Pencere moduna geçerken ekranın kullanılabilir alanına göre boyutlandır ve ortala.
- [ ] **Farklı ekranlarda kullanım kontrolü**
  - 1920×1080, 1366×768 ve 1280×720'de pencere/tam ekran; ayarlar, araç ipuçları ve sonuç panelini kontrol et. Metin taşması, küçük tıklama alanı veya klavye odağı sorunu bulunursa düzelt.
- [ ] **Sesleri gerçek çıkışta dinleme**
  - Müzik döngüsünü ve beş olay sesini kulaklık/hoparlörde dinle; geçiş, tıklama ve ses dengesini değerlendir. Mevcut doğrulama teknik sinyal/oynatma testidir; dinleme tamamlanmış sayılmasın.

## P2 — kurallar, adalet ve kullanım kolaylığı

- [ ] **Eşitlik kuralı (Karar gerekiyor)**
  - Aynı adımda iki pilot 12 altını geçerse `check_victory` listede ilk sıradakini, yani her zaman oyuncuyu kazanan yapıyor. Eşitlik kuralı seç (ör. daha az hasar, ortak zafer veya ek tur), sonuç ekranında göster, testini ekle.
- [ ] **Kanca çözüm sırası (Karar gerekiyor)**
  - Kancalar pilot kimliği sırasıyla tek tek uygulanıyor; karşılıklı veya aynı hedefe atılan kancalarda sonucu oyuncu numarası belirliyor. Hareketteki gibi eşzamanlı veya dönen öncelikli çözüm değerlendir.
- [ ] **İlk tur rüzgârı ve düşen pilotun programı (Karar gerekiyor)**
  - Köşe başlangıçlarında ilk rüzgâr pilotu doğrudan duvara itebiliyor. Yeniden doğan pilot turun kalan komutlarını başlangıç noktasından uygulamaya devam ediyor. İkisinin de bilinçli kural olup olmadığına karar ver; README'de yaz.
- [ ] **Maçı terk etmeden ayarlar**
  - Oyun içinden ses, hareketi azalt ve bekleme ayarlarına erişim ekle. Açık panel arkadaki girdiyi engellesin; maçı sıfırlamasın, devam eden turla çakışmasın.
- [ ] **Kısa oyun içi rehber**
  - Üç komut → rüzgâr → kontrat → teslimat akışını ve çapanın tek rüzgâr etkisini anlatan, kapatılabilir bir rehber ekle. Menüden yeniden açılabilsin.

## P3 — teknik borç ve performans

- [ ] **Kullanılmayan eski arayüz kodunu kaldırma**
  - `main.gd` içindeki programatik `build_shell/build_menu/build_game_ui`, eski `refresh_ui`, eski kaya/kargo verisi ve `main.tscn`'deki gizli `Forward1…Anchor` TextureButton + `*Desc` düğümleri artık kullanılmıyor ama gizli düğmeler hâlâ sinyale bağlı. Mantığı `main.gd`'de, arayüzü `main_ui.gd`'de bırakacak şekilde ayıkla; regresyon testleri değişmeden geçsin.
- [ ] **Ayarların her kaydırıcı adımında diske yazılması**
  - Müzik/efekt/bekleme kaydırıcıları sürüklenirken her `value_changed` çağrısında `settings.cfg` yazılıyor. Değeri anında uygula, kaydetmeyi `drag_ended` veya kısa gecikmeyle yap.
- [ ] **Uçuş kaydının sınırsız büyümesi**
  - Uzun maçlarda `RichTextLabel` metni sürekli büyüyor. Son birkaç turu tut veya satır sınırı koy.
- [ ] **Açılışta ses üretimi**
  - Müzik ve efektler `_ready` içinde GDScript döngüsüyle (~300 bin örnek) üretiliyor. Düşük donanımda açılış takılmasını ölç; gerekirse sesleri bir kez üretip `.wav` olarak depoya ekle.
- [ ] **Test kapsamı**
  - Mevcut regresyon (Godot 4.6.1'de 2235 kontrol, 0 hata) bot kilitlenmesini, eşitliği ve karşılıklı kancayı kapsamıyor. Bu durumlar için test ve botlar-arası kısa bir maç simülasyonu (maçın makul turda bittiğini doğrulayan) ekle.

## P4 — paylaşılabilir sürüm

- [ ] **Windows dışa aktarma ve paket kontrolü**
  - Depoda dışa aktarma önayarı yok. Windows önayarı ve kısa paketleme yönergesi ekle; paketi Godot editörü olmayan ortamda açılış, tam maç, ses ve ayar kalıcılığı açısından doğrula.
- [ ] **Tanıtım ve kullanım belgelerini güncelleme**
  - README'deki ayarlar/test kapsamını güncelle; güncel oyun, zafer ve ayarlar ekranlarını ekle. `project.godot` 4.7 özellik etiketi taşıyor, README/AGENTS ise 4.6+ diyor; hedef sürümü netleştir ve test edilen sürümleri yaz.
