# Görev Dağılımı

İki ajanın güçlü olduğu alanlara göre bölünmüştür. Her görev tek bir tarafa
aittir — çakışma olmasın diye. Bitirdiğini işaretle ve PR aç.

**Codex** → görsel üretim, metin/dil, silah davranışları
**Claude** → sistem mimarisi, denge matematiği, test altyapısı, meta ilerleme

> Son güncelleme: 2026-08-29 — Faz 4 ve Codex silah turu sonrası yeniden bölündü.

---

## 0. ÖNCE BU — dal birleştirme sırası

Şu an **üç dal** var ve hiçbiri `main`'e girmedi. `main` iki taraftan da geride.
Yeni işe başlamadan önce bu temizlenmeli, yoksa fark her gün büyür.

| Dal | Sahip | İçerik | Durum |
|---|---|---|---|
| `feat/phase4-difficulty` | Claude | Faz 4: zorluk, sektör modifier, lanet, kasa, ascension | Hazır, doğrulandı |
| `feat/codex-art` | Codex | Mine Launcher, Mortar, kart eli rastgeleliği, Plazma yuva birleşimi | Hazır |
| `feat/integration-phase5` | Claude | Yukarıdaki ikisinin birleşimi — **ölçüm ve doğrulama için**, `main`'e merge edilmek için değil | Doğrulandı |

`feat/integration-phase5` neden var: Faz 5.2 (8 silahlı denge) tek bir dalda
ölçülemiyordu — phase4'te 5 silah var, 8 değil. `main`'e dokunmadan ikisini
birleştirdim, ölçtüm, doğruladım. **Birleşik yapı headless koşuda 0 hata
veriyor** — yani açacağın iki PR güvenle birleşecek.

**Deneme birleştirme yapıldı: çakışma YOK.** Ortak dosyalarda temas noktaları:

- `game_manager.gd` — Codex 2 sabit ekledi, Claude ~238 satır. Farklı bölgeler.
- `main.gd` — Codex F8 debug kısayolunu sildi, Claude ~230 satır ekledi. Farklı bölgeler.
- `card_pool.gd` / `card_system.gd` — yalnızca Codex dokundu.

**Önerilen sıra:** önce `feat/phase4-difficulty` → `main`, sonra
`feat/codex-art` → `main`. İkinci PR rebase ister ama çakışmasız geçer.

Her iki dal da `main`'e girmeden aşağıdaki yeni görevlere başlanmamalı.

---

## Tamamlananlar (bu turda kapandı)

**Claude — Faz 4**
- 4.1 Zorluk cezası kaldırıldı, eğri derinliğe taşındı
- 4.2 Lanet sistemi (`curses.gd` — haste/armor/hunted/frail) ve kasa
  mekaniği (`bank_carried_salvage`) eklendi
- 4.3 Sektör modifier'ları (`sector_modifiers.gd` — 7 sektör, isim + tagline +
  iniş/doluluk/patlayıcı/top hızı/saldırgan çarpanları)
- 4.4 Zafer ekranı (`_trigger_run_victory`) ve Ascension katmanları

**Codex — silahlar**
- Mine Launcher Lv1–3 (`mine_launcher_controller.gd`, `mine_launcher_mine.gd/tscn`)
- Mortar Lv1–3 (`mortar_controller.gd`, `mortar_shell.gd/tscn`)
- `weapon_system.ensure_runtime_controller()` — yeni silahlar artık `main.gd`'ye
  dokunmadan kuruluyor. **Bu iyi bir kanca; kalan silahlar bunu kullanmalı.**
- Kart eli tamamen rastgele; Plazma `card_pool.gd`'den `weapon_cards.gd`'ye taşındı
- `RARITY_LEGENDARY` nadirlik katmanı eklendi

Kart havuzu: **22 kart** (14 pasif + 8 silah).

**Claude — Faz 5 (bu tur)**
- 5.1 Elit tuğla — Faz 4'ün son eksik maddesi kapandı
- 5.3 İniş hızı doygunluğu ölçüldü ve düzeltildi; ascension artık hissediliyor
- 5.4 `_balance_probe.gd` denge ölçüm aracı
- 5.5 Koloni tavanı denetlendi — kapalı, iş gerekmiyor

---

## CODEX — Öncelik 1: Görsel açıklar (hâlâ açık, ACİL)

Bu blok geçen turda da 1. öncelikti ve hiç el değmedi. Silah sayısı 5'ten
8'e çıktığı için açık **büyüdü**.

### 1.1 Silah kartı görselleri — 8 silah, 2 görsel

`weapons/weapon_cards.gd` içinde sekiz silahın yedisi `plasma_card.png` veya
`ball_card.png` kullanıyor. Kart ekranında ayırt edilemiyorlar.

Gerekli: `assets/cards/` altına 7 PNG (mevcut kart görselleriyle aynı boyut/stil)

| Dosya adı | Konu |
|---|---|
| `arc_cannon_card.png` | Dallanan elektrik yayı, mor-cyan |
| `scatter_cannon_card.png` | Yelpaze şeklinde dağılan mermiler |
| `railgun_card.png` | Dikey ince ışın huzmesi, mavi-beyaz |
| `homing_missile_card.png` | İz bırakan güdümlü füze |
| `pulse_laser_card.png` | Sürekli ışın demeti, turuncu-sarı |
| `mine_launcher_card.png` | Sahada duran nabız atan mayın |
| `mortar_card.png` | Yay çizen havan mermisi, tepede patlama |

Sonra `weapons/weapon_cards.gd` içindeki `"icon"` yollarını güncelle ve import
çalıştır: `godot --headless --import --path .`

### 1.2 Pasif kart görselleri — 11 kart

Tek renk SVG ikonla görünüyorlar, silah kartlarının yanında sönük kalıyorlar.
`card_pool.gd` içindeki `"icon"` yolları güncellenmeli.

`paddle_width` · `xp_gain` · `drop_rate` · `magnet_duration` ·
`combo_window` · `extra_ball` · `crit_hit` · `salvage_find` · `ball_speed` ·
`revive` · `slow_descent`

### 1.3 Koloni bina görselleri — 3 bina

`colony/buildings/` altında altı `*_live.tscn` var, üçü eksik — o üçü
prosedürel yer tutucu olarak çiziliyor.

| Bina | Konu | Tema rengi |
|---|---|---|
| Kalkan Jeneratörü | Kubbe yayan enerji kulesi | `#52d8ff` |
| Eğitim Simülatörü | Hologram projektörlü kapsül | `#7dff9e` |
| Veri Arşivi | Veri sütunlu sunucu kulesi | `#c98bff` |

Mevcut binaların yapısını örnek al: `colony/buildings/*_live.tscn`

---

## CODEX — Öncelik 2: Metin ve dil

### 2.1 Silah kart açıklamalarını düzelt — 8 silah

`weapons/weapon_cards.gd` içindeki Lv1/Lv2/Lv3 açıklamaları kontrolcü kodundan
değil tahminden yazıldı. Gerçek davranışa göre düzelt. Mine Launcher ve Mortar
dahil — onları sen yazdın, açıklamaları da senden.

### 2.2 Oyun içi Krediler ekranı — yasal zorunluluk

game-icons.net ikonları CC BY 3.0, atıf istiyor. Ana menüye erişilebilir bir
"Krediler" ekranı gerekiyor. İçerik `CREDITS.md`'de hazır.
**`main.tscn`'e düğüm ekleme — koddan üret.**

### 2.3 CREDITS.md'yi tamamla

8 ikonun yazarı bilinmiyor: `circuitry` · `cog` · `gears` · `metal-bar` ·
`microchip` · `time-trap` · `token` · `two-coins`
game-icons.net'ten tek tek doğrula.

### 2.4 Sektör atmosfer metni — kapsam daraldı

Yedi sektörün **adı ve tagline'ı artık var** (`sector_modifiers.gd` içinde,
Faz 4'te eklendi). Sana kalan: geçiş ekranındaki sunum ve daha uzun atmosfer
metni (`main.gd` → `_play_sector_transition`).
**Not:** `sector_modifiers.gd` Claude bölgesi. İsimleri beğenmezsen değiştirme,
söyle — birlikte karar verelim.

---

## CODEX — Öncelik 3: Kalan iki silah

Mine Launcher ve Mortar'da kurduğun `ensure_runtime_controller` kancasını kullan.

- **Drone Bay** — raketin yanında 1–2 mini drone, bağımsız ateş
- **Orbital Marker** — tuğla işaretlenir, telegraf sonrası dikey ışın

Her biri: `<isim>_controller.gd` + gerekiyorsa `<isim>_visual.gd`, sonra
`weapons/weapon_cards.gd`'ye kayıt. **`main.gd`'ye dokunmak gerekmez.**

---

## CLAUDE — Faz 5: Denge doğrulama

### 5.1 Elit tuğla — ✅ BİTTİ

Faz 4'ten kalan tek maddeydi. Yüksek can (3/4/5, derinliğe göre) + kehribar
nabızlı çerçeve + 3x düşürme çarpanı. `elite_bricks.gd`.

Kalibrasyon notu: oran **tuğla başınadır** ve satır boyunca birikir. İlk
deneme derinlik 25'te satırların %81'ini elitli yapıyordu. Satır bazlı
yeniden ölçüldü — şimdi derinlik 4'te satırların ~%12'si, derinlik 20+'da
~%45'i. Satır başına en fazla 1 elit.

### 5.3 Ascension × sektör modifier etkileşimi — ✅ BİTTİ

Ölçüm, endişenin **tersini** gösterdi: iniş hızı kontrolden çıkmıyor, taban
zaten yakalıyor. Sorun tabanın **çok erken** bağlamasıydı.

- Taban ağır senaryoda derinlik 9'da bağlıyordu
- Ascension 10'da ham değer 0.123s, oyuncunun yaşadığı 0.450s
- Yani ascension, iniş hızı açısından **kozmetikti** (+%15/katman kazanç
  veriyordu, karşılığında hiçbir baskı getirmiyordu)

İki düzeltme:
1. Taban da ascension ile iniyor (katman başına %2): asc0 → 0.450,
   asc10 → 0.368. Yalnızca ascension tabanı deler; lanet ve sektör delemez.
2. Sektör 6 ve 7'nin `descent_scale`'i **ölü sayıydı** (depth 21/25'te
   başlıyorlar, taban depth 9-13'te bağlıyor). Baskı doygun olmayan
   eksenlere taşındı: satır doluluğu ve saldırgan sıklığı.

**Yeni sektör/lanet eklerken:** derinlik 9'un ötesinde `descent_scale` ile
baskı kurmaya çalışma, taban yutar. Doygun olmayan eksenleri kullan.

### 5.4 Test altyapısı — ✅ BİTTİ

`_balance_probe.gd` — `_` önekli, `.gitignore`'da, depoya girmez.
Ölçtüğü: iniş aralığı çarpımsal yığını, tabanın bağlama derinliği,
sektör `descent_scale`'lerinin gerçekten etkili olup olmadığı, elit oran
eğrisi, koloni PARÇA gideri.

```bash
godot --headless --path . --script _balance_probe.gd
```

Kendinde yok — yerel araç. Denge sayısına dokunacaksan önce bunu yaz.

### 5.5 Koloni tavanı — ✅ İŞ GEREKMİYOR (denetlendi)

Tavan zaten kapalı: kalibrasyon üstel bir gider (40 × 1.35^n), ascension
kazancı doğrusal (+%15/katman, tavan 2.5x). Ölçüm: kalibrasyon 20'ye
ulaşmak maksimum ascension'da ~530 run. Üstel gider doğrusal geliri uzak
ara geçiyor.

Kazanç çarpanının üç yolda da (PARÇA, coin, XP) **bir kez** uygulandığı
denetlendi; çift sayım yok.

### 5.2 8 silahlı denge geçişi — ✅ BİTTİ

`main`'e dokunmadan `feat/integration-phase5` dalında iki dal birleştirilip
ölçüldü (bkz. bölüm 0).

**Yuva doldurma sorun DEĞİL.** Endişe yersizdi — 22 kartlık havuzda 8 silah,
2 yuva:

| Oyuncu davranışı | İlk yuva | İki yuva | 40 level-up'ta dolmayan |
|---|---|---|---|
| Silah öncelikli | 1.3 | 2.9 | %0 |
| Rastgele seçim | 2.8 | 6.0 | %0 |

Rastgele el, silah bulmayı zorlaştırmamış. Ek iş gerekmiyor.

**Bulunan gerçek hata: bayat silah sayacı.** `get_active_weapon_count()`
`[plasma_level, pierce_level, fireball_level]` sayıyordu — silah yuva sistemi
öncesinin üç "silah kartı". Plazma yuva sistemine taşınıp 7 silah eklenince
sayaç kör kaldı.

Ölçüm: oyuncu **Railgun + Mortar ile iki yuvayı da doldurduğunda sayaç hâlâ
0 dönüyordu.** Sonuç: ÇEKİRDEK ağırlığı (60) run boyunca hiç düşmüyor,
`pierce` ve `fireball` sürekli fazla teklif ediliyordu. Tasarım niyeti
"iki saldırı seçeneği olana kadar çekirdek kartlar öne çıksın" idi; adım
asla gerçekleşmiyordu.

Düzeltildi: artık dolu yuvalar + pierce/fireball sayılıyor.
Railgun + Mortar → sayaç 2, ÇEKİRDEK ağırlığı 60 → 26.

Ölçüm aracı: `_weapon_probe.gd` (gitignore'da).

## CODEX'E BİLDİRİM — bölge dışı bulgu, dokunmadım

CLAUDE.md bölüm 2 gereği düzeltmedim, bildiriyorum. Onay verirsen ben de
yapabilirim.

### `RARITY_LEGENDARY` teklif edilemez durumda

`card_pool.gd`'ye `RARITY_LEGENDARY` eklenmiş (renk + etiket hazır), ama
`card_system.get_rarity_weight()` içinde **karşılığı yok**. Bu yüzden
`match` sonundaki `return 1.0`'a düşüyor:

| Nadirlik | Ağırlık |
|---|---|
| ÇEKİRDEK | 60 / 26 |
| YAYGIN | 45 |
| NADİR | 12 → 32 (derinlikle) |
| EFSANE | 3 → 14 (derinlikle) |
| **LEGENDARY** | **1.0** ← yaygının 1/45'i |

Şu an hiçbir kart bu nadirliği kullanmadığı için oyunda etkisi yok. Ama
eklediğin ilk legendary kart pratikte hiç çıkmayacak. Ağırlığı sen
belirlemelisin — ilk legendary kartı sen tasarlayacaksın.

Not: `RARITY_LABELS` içinde etiket `"LEGENDARY"` yazıyor; diğerleri Türkçe
(YAYGIN, NADİR, EFSANE). `EFSANE` zaten `RARITY_EPIC`'te kullanılmış, yani
yeni katman için başka bir Türkçe ad gerekiyor.

### Yayın öncesi temizlik

İkisi de `OS.is_debug_build()` korumalı — sürüm derlemesinde erişilemez.
Riskli değil, sadece listeye alınsın:

- `game_manager.debug_print_weapon_slots()` — her silah alımında konsola
  iki satır yazıyor. Denge ölçümü yaparken çıktıyı boğuyor.
- Koloni debug kısayolları (`colony.gd` `_unhandled_input`): Shift+P
  100 PARÇA ekliyor, Shift+R **koloni binalarını siliyor**. Kısayol masaüstü
  debug derlemesiyle sınırlı, ama Shift+R geri alınamaz bir işlem —
  yayından önce kaldırılmalı.

---

## Bölge hatırlatması

`CLAUDE.md` / `AGENTS.md` bölüm 1'deki tablo geçerli. Yeni dosyalar:

| Dosya | Sahip |
|---|---|
| `curses.gd`, `sector_modifiers.gd`, `elite_bricks.gd` | CLAUDE |
| `mine_launcher_*.gd/tscn`, `mortar_*.gd/tscn` | CODEX |
| `weapons/weapon_system.gd`, `weapons/weapon_cards.gd` | CODEX (ortak dosya, silah bölgesi) |

Bölge dışında hata görürsen: **düzeltme, bildir, onay bekle.**
