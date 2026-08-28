# Görev Dağılımı

İki ajanın güçlü olduğu alanlara göre bölünmüştür. Her görev tek bir tarafa
aittir — çakışma olmasın diye. Bitirdiğini işaretle ve PR aç.

**Codex** → görsel üretim, metin/dil, silah davranışları
**Claude** → sistem mimarisi, denge matematiği, test altyapısı, meta ilerleme

---

## CODEX — Öncelik 1: Görsel açıklar

Bunlar oyunun şu an en görünür eksikleri.

### 1.1 Silah kartı görselleri — ACİL

Beş silahın **hiçbirinin kendi kart görseli yok.** Şu an dördü
`plasma_card.png`, biri `ball_card.png` kullanıyor — yani kart ekranında
dört silah birbirinin aynı görünüyor.

Gerekli: `assets/cards/` altına 5 PNG (mevcut kart görselleriyle aynı boyut/stil)

| Dosya adı | Konu |
|---|---|
| `arc_cannon_card.png` | Dallanan elektrik yayı, mor-cyan |
| `scatter_cannon_card.png` | Yelpaze şeklinde dağılan mermiler |
| `railgun_card.png` | Dikey ince ışın huzmesi, mavi-beyaz |
| `homing_missile_card.png` | İz bırakan güdümlü füze |
| `pulse_laser_card.png` | Sürekli ışın demeti, turuncu-sarı |

Sonra `weapons/weapon_cards.gd` içindeki `"icon"` yollarını güncelle.

### 1.2 Pasif kart görselleri — 11 kart

Bu kartlar şu an tek renk SVG ikonla görünüyor; silah kartlarının yanında
sönük kalıyor. `card_pool.gd` içindeki `"icon"` yolları güncellenmeli.

`paddle_width` · `xp_gain` · `drop_rate` · `magnet_duration` ·
`combo_window` · `extra_ball` · `crit_hit` · `salvage_find` · `ball_speed` ·
`revive` · `slow_descent`

### 1.3 Koloni bina görselleri — 3 bina

Faz 3'te eklenen üç bina şu an **prosedürel yer tutucu** (neon kenarlıklı
panel + nabız atan çekirdek). Diğer altı binanın canlı sahnesi var, bunların
yok.

| Bina | Konu | Tema rengi |
|---|---|---|
| Kalkan Jeneratörü | Kubbe yayan enerji kulesi | `#52d8ff` |
| Eğitim Simülatörü | Hologram projektörlü kapsül | `#7dff9e` |
| Veri Arşivi | Veri sütunlu sunucu kulesi | `#c98bff` |

Mevcut binaların yapısını örnek al: `colony/buildings/*_live.tscn`

---

## CODEX — Öncelik 2: Metin ve dil

### 2.1 Silah kart açıklamalarını düzelt

`weapons/weapon_cards.gd` içindeki Lv1/Lv2/Lv3 açıklamalarını **ben tahminle
yazdım** — kontrolcü kodundan silahların seviye başına tam olarak ne yaptığını
çıkaramadım. Gerçek davranışa göre düzelt.

### 2.2 Oyun içi Krediler ekranı

Şu an yok, ama **yasal zorunluluk**: game-icons.net ikonları CC BY 3.0 ve atıf
istiyor. Ana menüye erişilebilir bir "Krediler" ekranı gerekiyor.
İçerik `CREDITS.md`'de hazır.

### 2.3 CREDITS.md'yi tamamla

8 ikonun yazarı bilinmiyor: `circuitry` · `cog` · `gears` · `metal-bar` ·
`microchip` · `time-trap` · `token` · `two-coins`
game-icons.net'ten tek tek doğrula.

### 2.4 Sektör isimleri ve atmosfer metni

Yedi sektörün adı yok, sadece numara. Sektör geçiş ekranı hazır ve metin
bekliyor (`main.gd` → `_play_sector_transition`).

---

## CODEX — Öncelik 3: Kalan silahlar

Artifact'teki Kademe B ve C. Mevcut beş silahın deseni takip edilerek.

- **Mine Launcher** — sahanın ortasına sabit mayın, tuğla değince patlar
- **Mortar** — mermi tepeye çıkar, en üst satırda patlar
- **Drone Bay** — raketin yanında 1–2 mini drone, bağımsız ateş
- **Orbital Marker** — tuğla işaretlenir, telegraf sonrası dikey ışın

Her biri: `<isim>_controller.gd` + gerekiyorsa `<isim>_visual.gd`, sonra
`weapons/weapon_cards.gd`'ye kayıt. **`main.gd`'ye dokunmak gerekmez.**

---

## CLAUDE — Faz 4: Sistem ve denge

### 4.1 Zorluk cezasını kaldır (F4)

Dört sistem oyuncuyu güçlendiği için cezalandırıyor: iniş hızı, satır
doluluğu, zırh/kalkan oranı, yan saldırgan sıklığı. Build-tabanlı cezayı
kaldır, eğriyi derinliğe taşı.

### 4.2 Risk mekanikleri (F8)

Kasa mekaniği (boss sonrası "koloniye dön ve garantiye al"), lanet sistemi
(gönüllü zorluk ↔ ödül çarpanı), elit tuğla.

### 4.3 Sektör modifier'ları (F9)

Yedi sektör şu an sadece arka plan rengi. Her sektöre mekanik imza:
düşük yerçekimi, sis, manyetik sapma, ikiz saldırgan.

### 4.4 Zafer ve Ascension (F10)

Chronoform sonrası "RUN TAMAMLANDI" ekranı, ardından Ascension katmanları.
Bu aynı zamanda koloni tavanı sorununu da kapatır.

### 4.5 Sürekli

Test altyapısı, birleştirme denetimi, denge matematiği.

---

## Ortak — ikisi de dokunabilir, önce haber ver

- `assets/_archive/` (35 MB) depoya alınmadı. Silinecek mi karar verilmeli.
- Müzik dosyasının lisansı netleşmeli (public repo kararını etkiliyor).
- Silahların oyunda gerçekten ateş ettiği **henüz test edilmedi.**

---

## Çakışma kuralı

`main.gd` ve `game_manager.gd` ortak dosya. Genişletme noktaları sayesinde
çoğu iş bunlara dokunmadan yapılabilir — bkz. `AGENTS.md` madde 3.
Dokunman gerekiyorsa önce `git fetch` yap, sonra karşı tarafa haber ver.
