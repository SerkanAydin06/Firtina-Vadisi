# Fırtına Vadisi — geliştirme listesi

Öncelik sırası aşağıdadır. Yeni geliştirmeye başlamadan kullanıcı tarafından seçilen kapsamı esas al.
Durum: `[ ]` bekliyor, `[x]` tamamlandı; aktif maddenin yanına “Devam ediyor” ekle.

## P1 — oynanışı anlaşılır ve canlı hâle getir

- [x] **Rota önizlemesi**
  - Seçili üç komutun motor ve rüzgâr adımlarını ayrı işaretlerle göster.
  - Duvar/kaya ve mevcut gemi konumlarından doğan çarpışma riskini belirt.
  - Rakiplerin gizli komutları bilinmediği için önizlemenin tahmini olduğunu açıkça göster.
  - Komut ekleme/çıkarma/temizleme ve yeni turda güncelle; oyun durumunu değiştirme.
- [x] **Kontrat ve hedef takibi**
  - Taşınan kontratın hedef iskelesini vurgula; yük, hedef ve ödülü okunaklı göster.
  - Kontrat/iskeleden bilgi alınabilsin; teslimat ve yeniden doğmada eski vurgu temizlensin.
- [x] **Hareket ve olay efektleri**
  - Yumuşak zeplin dönüşü, motor izi, kanca halatı, çarpışma kıvılcımı ve teslimat parlaması.
  - Efektler oturum değişiminde temizlensin, girdiyi engellemesin; hareketi azalt seçeneği olsun.

## P2 — tur akışı ve sonuç sunumu

- [x] **Tur sunumu**
  - Çözülen komut slotunu vurgula; komut/rüzgâr aşaması açıkça görünsün.
  - Tur sonunda planlama durumuna dön; menüye dönüş, yeni maç ve zafer eski vurguları temizlesin.
- [x] **Zafer ekranı**
  - Kazanan, altına göre sıralama, teslimat sayıları, yeniden oyna ve ana menü eylemleri.
  - Sonuç paneli arkadaki oyun girişini engellesin; istatistikler yeni maçta sıfırlansın.
- [x] **Ses ve atmosfer**
  - Rüzgâr, motor, kanca, çarpışma ve teslimat sesleri; uygun arka plan müziği.
  - Müzik/efekt sesleri ayrı ve kalıcı ayarlansın; sesler üst üste sınırsız birikmesin.
  - Kullanılan seslerin lisansı/kaynağı kayıtlı olsun.

## P3 — editör ve bakım kolaylığı

- [ ] **Editörde aynı görünüm**
  - Çalışma zamanındaki yeni arayüz Godot sahne editöründe de görülsün ve düzenlenebilsin.
  - Editör önizlemesi oyun başlatmasın, kullanıcı ayarlarını değiştirmesin, düğüm/sinyal çoğaltmasın.
  - Düzenin tek kaynağı olsun; F5 görünümü ve etkileşimleri korunarak doğrulansın.

## Tamamlanan temel işler

- [x] Tur iptali, yeniden başlatma, çapa, kargo, hareket/itiş ve yeniden doğma düzeltmeleri — PR #2.
- [x] Rüzgâr/engel farkında bot rotaları; kalıcı tam ekran ve bekleme ayarları — PR #2.
- [x] Vadi haritası, uçuş konsolu, SVG ikonlar ve tıklayarak komut kaldırma — PR #3.
- [x] `presentation.gd` tam sayı bölmesi uyarısı — PR #4.
- [x] ChatGPT/Codex ve Claude Code için kısa ortak çalışma talimatları.
