# Fırtına Vadisi — Godot 4 Prototype

Bu paket görsel asset kullanmadan oyun çekirdeğini test etmek için hazırlanmıştır.

## İçerik
- 11x9 grid kanyon haritası
- 1 insan oyuncu + 3 AI pilot
- Her tur 3 gizli komut programlama
- Komutlar: İleri 1, İleri 2, Sola Dön, Sağa Dön, Kanca, Çapa
- Her komut slotundan sonra rüzgâr
- Intent -> Resolve -> Animate ayrımı
- Aynı hücre hedefi, kafa kafaya çarpışma ve domino itme zinciri
- Kayaya/kanyon sınırına çarpma hasarı
- İki kargo rotası ve teslimat altını
- 12 altına ulaşınca zafer
- Tween tabanlı placeholder hareket animasyonları

## Çalıştırma
Godot 4.x ile `project.godot` dosyasını açıp F6/F5 ile çalıştırın.

## Görsel ekleme için
Oyun mantığı `scripts/main.gd` içinde, grid çizimi `scripts/board.gd`, zeplin placeholder çizimi `scripts/airship_token.gd` içindedir. Sonradan Sprite2D/TextureRect tabanlı görseller eklenirken oyun mantığını değiştirmek gerekmez.
