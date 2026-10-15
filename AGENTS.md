# Fırtına Vadisi — ortak yapay zekâ talimatları

Bu dosya ChatGPT/Codex ve Claude Code için ortak proje yönergesidir.
Kapsam: bu depo. Güncel kullanıcı isteği ve platform kuralları önceliklidir.

## Kısa ve ekonomik çalış

- Türkçe yanıtla. İşe başlarken tek cümle; bitirirken değişiklik, doğrulama ve varsa engel için en fazla 5 kısa madde kullan. Kullanıcı ayrıntı isterse aç.
- Uzun giriş, tekrar özet, düşünce dökümü, tüm kod/diff/log çıktısı ve gereksiz alternatif üretme.
- Uzun işlerde yalnızca anlamlı ilerleme/engel bildir; aracın zorunlu bildirim kurallarını koru.
- Önce `git status --short`, sonra görevle ilgili `rg` araması yap. Tüm depoyu baştan okuma.
- Dosyaların yalnızca ilgili bölümlerini oku; aynı içerik değişmedikçe tekrar okuma. Bağımsız okumaları tek çağrıda grupla, çıktıyı sınırla.
- Görev yerel kodla çözülebiliyorsa web araması, yeni araç/bağımlılık, görsel üretimi veya alt ajan başlatma. Güncel dış bilgi gerekiyorsa doğrula.
- Küçük işte uzun plan yapma. Gereken en küçük tutarlı değişikliği yap; ilgisiz refaktör ve biçimlendirme yapma.
- Önbellek, üretilmiş dosya ve büyük görselleri metin olarak okuma; gerektiğinde ilgili görseli doğrudan incele.

## Görev ve TODO disiplini

- `TODO.md` içinden yalnızca ilgili maddeyi oku. Liste yol haritasıdır; bütün maddeleri kendiliğinden uygulama yetkisi değildir.
- Kullanıcı bir maddeyi seçerse tamamlayana veya gerçek bir engele kadar sürdür. Rutin uygulama tercihleri için tekrar izin isteme.
- Başlanan maddeyi “Devam ediyor”, doğrulanıp tamamlanan maddeyi `[x]` yap. Yapılmayan işi tamamlandı gösterme.
- Yeni işi yalnızca istenmişse veya bulunan somut bir kusurun takibi için ekle. TODO'ya uzun oturum günlükleri yazma.

## Dosya haritası

- `project.godot`, `scenes/main.tscn`: Godot 4.6+, giriş sahnesi.
- `scripts/main.gd`: tur, hareket/itiş, rüzgâr, botlar, hasar, zafer.
- `scripts/main_ui.gd`: aktif arayüz, kontratlar, başlangıçlar ve ayarlar.
- `scenes/main.tscn`, `scenes/board.tscn`: editör ve oyun için ortak görsel düzen; yeni statik arayüzü sahnede düzenle.
- `scripts/presentation.gd`: ortak renk/stil yardımcıları ve komut ikonları.
- `scripts/board_topdown.gd`, `scripts/board.gd`: tahta, koordinatlar ve animasyonlar.
- `scripts/airship_token.gd`, `scenes/airship_token.tscn`: zeplin görselleri.
- `assets/ui/`: yeni SVG görselleri; `assets/generated/`: mevcut PNG'ler.
- `tests/regression.gd`: oyun akışı regresyonları; `README.md`: kurallar ve çalıştırma.

## Korunacak davranışlar

- Kullanıcı istemedikçe oyun kurallarını/dengeyi değiştirme. Yerleşim hesabında örtük tam sayı bölmesi kullanma.
- Yeni asenkron işler oturum değişiminde iptal edilmeli; eski tur/animasyon yeni maça müdahale etmemeli.
- Komut, kargo, rüzgâr ve çarpışma değişikliklerinde mevcut tek-adım hareket ve tek-rüzgâr çapa davranışlarını koru.
- Arayüzde teknik açıklama/debug metni gösterme. Yeni görseller mevcut petrol mavisi/pirinç diline uysun.
- Sahne düğüm yollarını ve bağlı sinyalleri koru; programatik düzenin editör görünümünden farklı olabileceğini hesaba kat.

## Doğrulama ve teslim

- Önce küçük ve ilgili kontrolü yap. Salt belge değişikliğinde motoru/test paketini çalıştırma; bağlantı, kapsam ve `git diff --check` yeterlidir.
- GDScript değişikliğinde uygun olduğunda `godot --headless --path . --script <dosya.gd> --check-only` kullan.
- Oyun mantığı veya etkileşim değişikliğinde `godot --headless --path . --script tests/regression.gd` çalıştır. İlk kurulum/yeni kaynakta gerekirse `godot --headless --path . --editor --import` yap.
- Kayda değer görsel değişikliği gerçek oyun görüntüsünde kontrol et. Görsel kontrol yapılamadıysa açıkça söyle.
- Aynı testi değişiklik olmadan tekrar çalıştırma; yeterli doğrulamadan sonra dur. Test sayısını/başarısını tahmin etme.
- Kullanıcının yerel değişikliklerini koru; force push, reset veya ilgisiz silme yapma. `.godot/`, sırlar ve yerel geçici dosyaları commit etme.
- Güncel uzak dalı kontrol et. Küçük, ilgili commit ve açıklaması kısa bir PR hazırla. Kullanıcının mevcut merge yetkisi varsa doğrulanan PR'ı tekrar onay istemeden birleştir; platform engellerini aşma.
- Sonuçta PR/commit bağlantısı ve gerçekten yapılan doğrulamayı belirt. Engeli ve eksik kalan işi gizleme.

Bu yönerge hesap kotasını, fiyatlandırmayı veya model ayarlarını değiştirmez; gereksiz iş ve çıktı miktarını azaltmayı hedefler.
