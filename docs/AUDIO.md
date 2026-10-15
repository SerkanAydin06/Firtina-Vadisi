# Ses kaynakları

Tüm sesler `scripts/game_audio.gd` içinde bu proje için matematiksel olarak sentezlenir. Harici kayıt, sample, beste veya ses kütüphanesi kullanılmaz; üçüncü taraf ses lisansı/atıf gereksinimi yoktur. Kod ve ürettiği içerik deponun lisans koşullarına tabidir; bu belge ek bir lisans vermez.

- Rüzgâr: filtrelenmiş gürültü.
- Motor: düşük frekanslı osilatör ve gürültü.
- Kanca: düşen metalik ton.
- Çarpışma: kısa bas darbesi ve gürültü.
- Teslimat: üç notalı bildirim.
- Müzik: 16 saniyelik özgün, düşük yoğunluklu minör arpej ve bas döngüsü.

16 kHz mono PCM kaynakları başlangıçta bir kez oluşturulur. Efektler altı ses kanalıyla sınırlıdır; aynı olay 100 ms içinde tekrar tetiklenmez. Müzik ve efekt düzeyleri ayrı saklanır; sıfır sessizdir. Menü ve yeni maç önceki sesleri durdurur. Hareketi azalt ayarı sesi kapatmaz.
