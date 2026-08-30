# Görev Dağılımı

İki ajanın güçlü olduğu alanlara göre bölünmüştür. Her görev tek bir tarafa
aittir — çakışma olmasın diye. Bitirdiğini işaretle ve PR aç.

**Codex** → görsel üretim, metin/dil, silah davranışları
**Claude** → sistem mimarisi, denge matematiği, test altyapısı, meta ilerleme

> Son güncelleme: 2026-08-29 — Faz 5 sonrası.
>
> **Bu dosya İŞ listesidir.** Karşı tarafa MESAJIN varsa `ILETISIM.md`'ye yaz —
> birleştirme talimatı, bulduğun hata, cevap bekleyen soru oraya gider.

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

Kart havuzu: **18 kart** (10 pasif + 8 silah).

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

## CLAUDE — Faz 6: İlerleme eğrisi

### 6.1 Run'ın ikinci yarısı ilerleme vermiyordu — ✅ BİTTİ

Bir zafer run'ı depth 1 → 56 (7 boss). Boss segmenti başına level-up:

| Segment | Önce | Sonra |
|---|---|---|
| depth 1→8 | 6 | 7 |
| 8→16 | 3 | 4 |
| 16→24 | 2 | 3 |
| 24→32 | 1 | 2 |
| 32→40 | 1 | 2 |
| 40→48 | **0** | 1 |
| 48→56 | 1 | 2 |
| **toplam** | **15** | **21** |

Son çeyrek — 24 derinlik, ~2300 tuğla — 2 kart seçimi veriyordu, bir segment
sıfır. Run'ın en tehlikeli yarısı en ödülsüz yarısıydı.

Sebep: tuğla geliri derinlik 8'den sonra **sabit** (satır başına 12), XP
ihtiyacı **üstel** (×1.20/seviye). Sabit gelir üstel maliyeti yakalayamıyor.

Dört aday ölçüldü. Seçilen: **geliri derinliğe bağla, maliyet eğrisine
dokunma.** Orb XP'si `10 × (1 + 0.06 × (derinlik−1))` — d1=1.00, d56=4.30.

Maliyet eğrisini değiştirmek erken oyunu da şişiriyordu; gelir çarpanı erken
ölen oyuncuyu hiç etkilemiyor. Faz 4.1'in "eğriyi derinliğe taşı" ilkesiyle
aynı.

Havuz kapasitesi 48 seçim, yani 21 seçim hâlâ tercih bırakıyor — run her şeyi
maksimuma çıkarmıyor.

### Yan ölçüm: zafer run'ı ~12 dakika

Tuğla inişi 12.3 dakika (ascension 0), 9.1 dakika (ascension 10). Boss
dövüşleri hariç. Derinlik 56'da temizlenmesi gereken hız saniyede 9.2 tuğla.

**Modelleme hatası notu:** ilk hesabımda satırın her adımda doğduğunu
varsaymıştım, sonuç 4.2 dakika çıkmıştı. Yanlış — alan adımda 10px iniyor,
yeni satır ancak `gap_y` (29px) birikince doğuyor, yani satır başına ~2.9
adım. Düzeltildi. **6.1'in sonucunu etkilemiyor**: o hesap tuğla sayıyor,
süre değil.

### Sıradaki — henüz ölçülmedi

### 6.2 Boss HP ↔ oyuncu güç tavanı — ✅ ÖLÇÜLDÜ, karar bekliyor

`feat/integration-phase5` dalında ölçüldü (8 silah gerekiyordu).

**Boss HP:** 100 → 500, boss 1'den 7'ye ×5.0.

| Boss | Derinlik | asc0 | asc10 | Bir öncekine göre |
|---|---|---|---|---|
| CORE | 8 | 100 | 220 | — |
| SENTINEL | 16 | 145 | 319 | ×1.45 |
| CELESTIAL | 24 | 200 | 440 | ×1.38 |
| VOID | 32 | 260 | 572 | ×1.30 |
| SOVEREIGN | 40 | 330 | 726 | ×1.27 |
| ARCHITECT | 48 | 410 | 902 | ×1.24 |
| CHRONOFORM | 56 | 500 | **1100** | ×1.22 |

> **DÜZELTME (Faz 7.4):** bu tablonun ilk iki satırı önce yanlış yazılmıştı
> (ikisi de 180, toplam ×2.78). Sebep: `boss_sprite_entity.gd`'deki
> `_get_base_hp()` varsayılanını (180) okumuştum, ama **CORE ve SENTINEL o
> sınıfı hiç kullanmıyor** — `StaticBody2D`'den türüyorlar ve kendi
> `@export var max_hp` alanları var (100 ve 145).
>
> Gerçek eğri düşündüğümden **daha iyi**: ×1.45'ten ×1.22'ye yavaşlayan
> düzgün bir rampa. İlk iki boss bilinçli olarak daha kolay.
> Sonuç değişmiyor — hasar tavanı yine 5. bossta doluyor ve sonrasında
> boss HP'si %52 artıyor.

**Oyuncunun hasar kaynaklarının HEPSİ tavanlı:**

- 2 yuva × Lv3 = 6 seçim
- crit_hit(2) + extra_ball(2) + ball_speed(2) + pierce(3) + fireball(3) = 12 seçim
- **Tavan: 18 seçim.** Sonrasında hasar büyümez.

> **GÜNCEL DEĞİL (bkz. 8.0.1):** denge turunda `extra_ball` ve
> `ball_speed` kart olmaktan çıktı. Tavan artık **14 seçim** ve 5. bossta
> değil **3. bossta** doluyor. Aşağıdaki analiz o eski sayıya dayanıyor.

Run 21 seçim veriyor, yani hasar tavanına **5. bossta (depth 40)** ulaşılıyor.
O noktadan sonra oyuncu hasarı sabit, boss HP'si +%52 artıyor (330 → 500).

#### Bulgu 1 — tasarım tercihi, sorun olmayabilir

Son iki boss oyuncunun build ile cevap veremediği bir duvar. Final boss'un
duvar olması makul; burada bir karar var, hata yok.

#### Bulgu 2 — `[KARAR GEREKLİ]` ascension tek taraflı

**Ascension boss HP'sini katman başına %12 artırıyor ama oyuncunun hasar
tavanını hiç artırmıyor** — kartların `max_level`'ı sabit.

Chronoform: asc0'da 500 HP, asc10'da **1100 HP** — ve karşısında **birebir
aynı** maksimum build var. Ascension'ın verdiği tek şey +%15 kazanç, yani
aynı tavana daha erken ulaşmak.

Diğer ascension etkilerinden yapısal olarak farklı: iniş hızına oyuncu
beceriyle cevap verebiliyor, elit tuğlaya da. Boss HP'sine verebileceği
hiçbir cevap yok.

#### Karar: 2. yol — ascension hasar tavanını da açsın ✅ (yarısı yapıldı)

Onur 2. yolu seçti. İki yarısı var:

**Yapıldı — pasif hasar kartları** (`card_system.gd`). `crit_hit`,
`extra_ball`, `ball_speed`, `pierce`, `fireball` ascension eşiklerinde
+1 `max_level` alır:

| Ascension | Hasar tavanı | Seçim arzı |
|---|---|---|
| 0-4 | 18 seçim | 21-23 |
| 5-9 | 23 | 24-25 |
| 10 | 28 | 25 |

**Sayılar neden böyle — bağlayıcı kısıt tavan değil, SEÇİM ARZI.**
Ascension kazancı +%15/katman ama XP ihtiyacı üstel (×1.20/seviye): ×2.5
gelir ancak ~4 fazla seviye satın alıyor. İlk tasarladığım +1/3katman
(tavan 33) boşuna olurdu — oyuncunun eline o kadar seçim geçmiyor, açılan
tavan boş kalırdı. +2 ile sınırlandı.

**Bekliyor — silah tarafı (Codex).** 3. yuva ya da silah Lv4. Seviye başına
davranış her controller'da ayrı tanımlı; Lv4'ün ne yapacağına Codex karar
vermeli. `ILETISIM.md`'de soruldu.

#### Açığın ne kadarı kapandı — dürüst rakam

Boss HP asc10'da ×2.20; hasar kapasitesi ×1.56. **Açığın yaklaşık yarısı.**
Codex'in 3. yuvası gelse ×1.72 olur — yine tam kapanmaz.

Yani 2. yol tek başına yetmiyor. Oyun testinden sonra boss HP artışının
(%12/katman) da düşürülmesi gerekebilir — 1. yolun kısmi hâli.

Ölçüm aracı: `_boss_probe.gd` (gitignore'da).

### 6.3 Yan saldırgan eğrisi — ✅ ÖLÇÜLDÜ, sorun yok

`get_late_game_side_attacker_multiplier` depth 57'ye kadar ölçekleniyor.
Aralık kabaca yarıya iniyor:

| Derinlik | Çarpan | Aralık |
|---|---|---|
| 1-8 | 1.00 | 6-10s |
| 21-28 | 0.60 | 3.6-6.0s |
| 57+ | 0.44 | 2.6-4.4s |

**Düzleşmiyor.** Run'ın ikinci yarısında baskıyı sürdüren eksenlerden biri.
Değişiklik gerekmiyor.

### 6.4 Tehlike hattı ekonomisi — ✅ ÖLÇÜLDÜ

**Gereken temizleme hızı derinlik 24'te platoya çıkıyor:**

| Derinlik | Gereken tuğla/sn (asc0) | asc10 |
|---|---|---|
| 8 | 5.9 | 8.9 |
| 16 | 6.8 | 10.2 |
| 24 | 8.9 | 11.3 |
| 32-56 | **9.2** | **11.3** |

Depth 24'ten 56'ya kadar talep **sabit** — çünkü iniş tabanı onu sınırlıyor.

**Tampon:** ekranda ~15 satır sığıyor, yani derinlik 56'da ~20 saniye geri
kalma payı var. Cömert; kötü bir seri hemen öldürmüyor.

**Tampon bitince af yok:** tehlike hasarı 0.85s aralıklı, 3 canla sürekli
tuğla geçerse 2.5 saniyede ölüm. Yani zafer run'ı yukarıdaki hızı
**sürdürülebilir** tutturmayı gerektiriyor.

**Ulaşılabilir mi?** Kaba sınır: plazma Lv3 (0.70s aralık, yaylı atış) +
bir silah (arc 1.5s / scatter 1.2s, çoklu vuruş) + 3-5 top + patlayıcı
zincir ≈ 10-11 tuğla/sn. Gerekenin biraz üstünde. **Ama bu tahmin, ölçüm
değil** — gerçek cevap oyun testinden gelir, tablodan değil.

### Run'ın ikinci yarısı: toplu görünüm

Üç ölçüm birleşince tablo şu:

| Eksen | Depth 24-56 arası |
|---|---|
| Boss HP | büyüyor (200 → 500) |
| Yan saldırgan sıklığı | büyüyor (0.60 → 0.44) |
| XP ilerleme | 6.1 öncesi düzdü, **düzeltildi** |
| Tuğla temizleme talebi | **sabit** (9.2/sn) |
| Oyuncu hasar tavanı | **5. bossta doluyor** (6.2 kısmen açtı) |
| Elit tuğla oranı | **depth 20'de tavana vuruyor** |

İki eksen büyüyor, üçü düz. Kriz değil ama bilinçli bir denge olmalı —
ikinci yarıya baskı eklenecekse doğru yer tuğla talebi ya da elit oranı.

Ölçüm araçları: `_progression_probe.gd`, `_boss_probe.gd`, `_danger_probe.gd`,
`_ascension_probe.gd`, `_balance_probe.gd`, `_weapon_probe.gd` (hepsi
gitignore'da).

## CLAUDE — Faz 7: Kart doğruluğu ve ölçülmemiş sistemler

### 7.1 ZİNCİR BELLEĞİ kartı hasara etki etmiyordu — ✅ DÜZELTİLDİ

Kombo sistemi iki yarıya bölünmüş:

| Yarı | Dosya | Ne yapar |
|---|---|---|
| Görsel | `combo_manager.gd` | Rank yazısı, ekran sarsıntısı |
| Mekanik | `chain_lightning_manager.gd` | Hasar veren zincir şimşeği |

Eşikleri birebir aynı (`[3,6,9,…,27]`), taban süreleri de aynı (0.85s).
Ama `combo_window` kartının çarpanını **yalnızca görsel yarı** uyguluyordu.
Zincir şimşeği kendi `LEGACY_CHARGE_TIMEOUT` sabitini kullanıyor, karttan
hiç etkilenmiyordu.

Kart "Combo zinciri %75 daha uzun sürer" diyor. Oyuncu bunu zincir şimşeğinin
daha uzun sürmesi diye okur — öyle değildi. Bir seçim harcayıp ekrandaki
yazının daha uzun kalmasını alıyordun.

Süre artık ikisinde de aynı çarpandan geçiyor. Lv3'te 0.85s → 1.49s, ikisi
de eşit.

**Bu bir buff.** Zincir şimşeği rank 8'de 6 hedefe vuruyor; pencerenin %75
uzaması ciddi verim artışı. Faz 6.4'te çıkardığım kaba temizleme hızı
sınırında zincir şimşeğini hesaba katmamıştım — oyun testinde ayrıca izlensin.

### 7.2 Kart denetimi: 22 kartın hepsi — ✅ TEMİZ (biri hariç)

7.1 bir soruyu doğurdu: başka kaç kart vaat ettiğini yapmıyor? Hepsini
tek tek izledim — kart kimliğinden getter'a, getter'dan tüketim noktasına.

**Sonuç: yalnızca `combo_window` bozuktu.** Diğer 21 kart doğru bağlı.

Yöntem (tekrar edilebilir): `game_manager.gd` içinde `get_card_level(&"…")`
okuyan tüm fonksiyonlar çıkarılır, her birinin gerçekten çağrıldığı
doğrulanır. Getter'ı olmayan üç kart (`revive`, `pierce`, `fireball`) elle
izlenir.

Denetlenen ve doğru bulunan kartlar:

| Kart | Tüketim noktası |
|---|---|
| `paddle_speed` / `paddle_width` | `paddle.gd` |
| `xp_gain` | `main.add_xp` |
| `drop_rate` / `salvage_find` | `main._resolve_brick_collectible_drop` |
| `magnet_duration` | `main.gd` mıknatıs süresi |
| `extra_ball` | `main._refresh_persistent_extra_balls` |
| `crit_hit` / `ball_speed` | `ball.gd` |
| `slow_descent` | `continuous_brick_field.apply_depth_settings` |
| `revive` | `main.gd` — son can gidince `lives = 2` |
| `pierce` / `fireball` | `ball.gd` kendi seviye değişkenlerine |

**Uyarı:** kullanım sayısı doğruluk kanıtı değil. `combo_window`'un da iki
kullanımı vardı ve yine de bozuktu. Getter'ın çağrıldığını görmek yetmez,
**doğru** tüketim noktasında çağrıldığını görmek gerekir.

### 7.3 Koloni bina etkileri: tek kaynak — ✅ DÜZELTİLDİ

Aynı diziler **üç yere kopyalanmıştı** (`colony.gd` UI metni, `ball.gd`,
`main.gd`) ve birbirinden sapmışlardı. Oyuncuya gösterilen sayı ile oyunun
uyguladığı sayı tutmuyordu:

| Bina | Seviye | UI diyordu | Oyun veriyordu |
|---|---|---|---|
| Ateş Reaktörü | 3 | 3 ek tuğla | **4** |
| Delici Araştırma | 2 | 3 ek tuğla | **2** |

Diziler `game_manager.gd`'ye taşındı, hem oyun hem UI oradan okuyor.

**Ölü özellik:** Teknoloji Merkezi Lv2+ "maksimum candayken Heart +1/+2 PARÇA"
vaat ediyordu. Kod `collect_heart()` içinde **yazılmıştı** ama hiç
çalışmıyordu — önünde iki kapı vardı:

1. `_resolve_brick_collectible_drop` tam canda heart'ı hiç spawn etmiyordu
2. `heart_pickup._on_body_entered` tam canda `queue_free()` edip dönüyordu

İkisi de açıldı. Dönüşüm artık ödül banner'ı da gösteriyor.

**Kendi hatam:** önce "dört binanın seviye etkisi yok" sonucuna varmıştım.
Yanlıştı — `game_manager.gd`'deki getter'lara bakıp erken karar vermişim.
Seviye etkileri tüketen dosyalara dağılmış. Hepsinin etkisi vardı; sorun
kopyaların sapmasıydı.

**Ders:** bir sistemin bozuk olduğuna karar vermeden önce **tüm** tüketim
noktalarını ara. `grep get_colony_building_level` ilk bakışta görmediğim
altı çağrı yeri gösterdi.

### 7.4 Boss denetimi — ✅ KOD TEMİZ, RAPOR HATALIYDI

Kart ve koloni tarafında üç hata bulan yöntemi bosslara uyguladım:
vaat edilen ile yapılanı karşılaştır.

**Sonuç: boss sisteminde hata yok.** Ölü kanca yok, her ezilen kanca
gerçekten çağrılıyor, ascension HP ölçeklemesi üç mimaride de uygulanıyor.

**İki mimari bir arada:**

| Boss | Türediği sınıf | Ezdiği kanca |
|---|---|---|
| CORE, SENTINEL | `StaticBody2D` | 1 tane |
| Diğer beşi | `boss_sprite_entity.gd` | 13-15 tane |

İlk ikisi, taban sınıf yazılmadan önceki mimariden kalma. Bu bir hata
değil ama bilinmesi gereken bir ayrım: taban sınıfa eklenen her yeni
davranış ilk iki bossa **kendiliğinden gelmez.** Ascension HP ölçeklemesi
onlarda ayrı ayrı yazılmış ve doğru — ama bir sonraki eklemede bu
hatırlanmalı.

**Bulunan tek hata benimdi.** Faz 6.2'deki boss HP tablosunun ilk iki
satırı yanlıştı; düzeltildi (yukarıda).

**Yöntem notu:** ilk taramamda `_get_phase_message` "ölü kanca" olarak
çıktı. Yanlıştı — grep desenim `_get_phase_message()` arıyordu ama çağrı
argümanlı (`_get_phase_message(current_phase)`). Desen düzeltilince ölü
kanca kalmadı. Otomatik tarama sonucunu doğrulamadan raporlamamalı.

### 7.5 Kendi Faz 4 sistemlerimin denetimi — ✅ TEMİZ, ama bir keşif

Herkesin kodunu denetledim, kendiminkini denetlemedim. Yaptım.

**Lanet ve sektörün on ekseni de tüketiliyor** — hiçbiri ölü değil:

| Sistem | Eksen | Tüketildiği yer |
|---|---|---|
| Lanet | kazanç | `game_manager.gd` |
| Lanet | iniş | `continuous_brick_field.gd` |
| Lanet | zırh | `level_generator.gd` |
| Lanet | saldırgan | `side_attacker_spawner.gd` |
| Sektör | iniş, doluluk, patlayıcı, top hızı, saldırgan | beş ayrı dosya |

Kasa, zafer ekranı ve ascension açma akışı da bağlı ve ulaşılabilir.

#### `[ÖNEMLİ]` Ascension'ı test etmenin tek yolu Shift+G, sonra K

Ascension **son boss (CHRONOFORM, depth 56) yenilene kadar tamamen
görünmez.** Akış doğru çalışıyor:

`_trigger_run_victory()` → `register_ascension_clear()` →
`highest_ascension_cleared` −1'den 0'a çıkar → menüde seçici belirir.

Ama bunun anlamı şu: **Faz 4 ascension, 5.3 iniş tabanı ve 6.2 hasar
tavanı — hepsi kimsenin görmediği bir kapının arkasında.** Ascension 5-10
için ayarladığım dengeler hiç oynanmadı.

Debug tuşuyla açma yolu var ama **hiç belli değil**:

| Tuş | Sonuç |
|---|---|
| `G` | Chronoform başlar ama **progression boss DEĞİL** — yenmek zafer getirmez |
| **`Shift+G`** | Chronoform **progression boss olarak** başlar |
| `K` | Aktif bossu anında öldürür |

Yani **Shift+G → K** ascension'ı saniyeler içinde açar. Düz `G` açmaz.

Sebep: `start_boss_encounter(event.shift_pressed, &"chronoform")` —
ilk parametre `is_progression_boss` ve `shift_pressed`'e bağlı. Aynı şey
diğer altı boss tuşu için de geçerli (B, N, M, V, J, H).

Bu bir hata değil, ama bilinmeden ascension test edilemez. 25F öncesi
ascension'a bakılacaksa bu kombinasyon gerekli.

### 8.0 Denge turu (Onur talimatıyla) — ✅ YAPILDI

Faz 8'in "oyun testi bekliyor" kilidinden ayrı: Onur doğrudan bir denge
listesi verdi, uygulandı.

**Kaldırılan 4 kart** (havuz 22 → 18, pasif 14 → 10):

| Kart | Sebep |
|---|---|
| Raket Hızı | işlevsizdi |
| Hızlı Top | derinlik zaten hızlandırıyor |
| Geniş Raket | kart değil, güçlendirme olarak kalır |
| Ekstra Top | kart değil, güçlendirme olarak kalır |

**Düşürülen oranlar** (seviye başına): XP %20→5, Ganimet %25→5,
Mıknatıs %30→5, Kombo %25→5, Kritik %14→5, Hurda **%100→3**,
Yavaş İniş ikili %15 → %5. **17 açıklama metni de güncellendi.**

**Ekstra top yeniden yazıldı:** artık sahnedeki topu ikiye katlıyor
(1→2→4), toplar kalıcı, düşme şansı top sayısıyla ters orantılı.
Oran ölçülerek %1.5 → %0.5 (eskisinde oyuncu run'ın %58'ini tavanda
geçiriyordu).

**Boss ayarları:** CORE aynı anda en fazla 2 mermi. SENTINEL kalkan
döngüsü yumuşatıldı — jeneratör canı 14→8, pencere 10s→14s, ve
jeneratörler artık tam dolu yenilenmiyor (%75 azalarak). Ölçülen etki:
6 turda jeneratör hasarı 168→56, çekirdek süresi 60s→84s.

### 8.0.1 Denge turunun geçersiz kıldığı ölçümler — yeniden ölçüldü

Kendi değişikliklerim önceki ölçümlerimi kaydırdı. Yeniden ölçtüm:

| Ölçüm | Önce | Sonra | Sebep |
|---|---|---|---|
| **Hasar tavanı** | 18 seçim | **14 seçim** | `extra_ball` (2) ve `ball_speed` (2) kart olmaktan çıktı |
| Yuva doldurma (silah öncelikli) | 2.9 level-up | **2.6** | Havuz küçüldü, silah oranı arttı |
| Yuva doldurma (rastgele) | 6.0 level-up | **4.9** | Aynı sebep |
| Havuz bileşimi | 8 silah + 14 pasif | **8 + 10** | 4 pasif kart kaldırıldı |

#### Faz 6.2'nin sonucu değişti

Hasar tavanı 18'den 14'e indi ama **boss HP'si aynı kaldı.** Seçim arzı
boss başına 7, 11, 14, 16, 18, 19, 21 idi — yani tavan artık **5. bossta
değil, 3. bossta** doluyor.

Düz kalan aralık 5→7 iken şimdi **3→7**. O aralıkta boss HP'si 200'den
500'e çıkıyor: **+%150**.

**Ama bu düz bir kötüleşme değil.** Kaldırılan `extra_ball` kartı kalıcı
+1/+2 top veriyordu; yerine gelen güçlendirme **4 topa kadar** katlıyor.
Yani top sayısı — hasarın en büyük bileşenlerinden biri — kart ekonomisinden
**tamamen çıktı** ve daha yükseğe ulaşabiliyor.

Yani "hasar tavanı 14 seçim" artık toplam hasar potansiyelini ölçmüyor.
Doğru okuma: *kart seçimiyle alınabilen* hasar 14'te doluyor, gerisi
güçlendirmeden geliyor. Bu ikisini tek sayıda toplamak yanlış olur.

**Sonuç:** Faz 6.2'nin "boss duvarı" sorusu oyun testi olmadan artık daha
da cevaplanamaz — çünkü cevabı büyük ölçüde ekstra top güçlendirmesinin
ne sıklıkta geldiğine bağlı, ve o da ölçülmüş değil, modellenmiş.

### Faz 8 — oyun testi sonrası kalibrasyon (BAŞLAMADI, bloke)

Claude şeridinde ölçülebilir iş kalmadı. Faz 4-7'de ölçülen her şey
54 testle korunuyor; kalan yedi soru (aşağıda) oynanışla cevaplanıyor.

**Faz 8 şu üçü geldiğinde başlar:**

1. **Oyun testi çıktısı** — aşağıdaki yedi sorudan hangilerinin gerçek
   olduğu. Tahminle sabit çevirmek, Faz 5-7'de iki kez yanlış çıktı.
2. **Codex'in 3. yuva cevabı** (`ILETISIM.md` A4) — Faz 6.2'nin yarısı
   ona bağlı. Boss HP'sini düşürmek gerekip gerekmediği o cevaba göre
   belli olur.
3. **25F kapsamı** — feature freeze sonrası neyin değişebileceği.

**Faz 8'de yapılacak iş türü:** yeni sistem değil, mevcut sabitleri
gözlemlenen davranışa göre çekmek. Her değişiklik ilgili testi de
güncellemeli — test kırılırsa belge de kırılıyor demektir.

**Şu an yapılmaması gereken:** yedi sorunun cevabını tahmin edip sabit
çevirmek. Faz 6.4'te "9.2 tuğla/sn tutturulabilir" diye kaba bir sınır
çıkardım ve bunu tahmin olarak işaretledim; hâlâ öyle. Faz 7.1'de zincir
şimşeğini buff'ladıktan sonra o sınır zaten değişti ama yeniden
hesaplamadım — çünkü hesaplamanın kendisi tahmine dayanıyor.

### 25F için: oyun testi olmadan cevaplanamayan yedi soru

Faz 4-7 boyunca yedi yerde "bu tahmin, gerçek cevap testten gelir" dedim.
Dağınık kaldılar; 25F kararı için tek yerde toplanmaları lazım.

**Hepsi tek bir run'da gözlenebilir** — biri hariç (ascension, ayrı gerekiyor).

| # | Soru | Nereden geldi | Yanlışsa geri alması |
|---|---|---|---|
| 1 | **Derinlik 32+ yetişilebiliyor mu?** Gereken hız 9.2 tuğla/sn ve depth 56'ya kadar sabit. Kaba sınırım 10-11 dedi — ama bu tahmin. | Faz 6.4 | Kolay — tek sabit (`minimum_safe_step_interval`) |
| 2 | **Ascension 10'un iniş tabanı (0.368s) oynanabilir mi?** | Faz 5.3 | Kolay — tek sabit |
| 3 | **Elit tuğla çerçevesi ayırt ediliyor mu?** Zırhlı beyaz, kalkanlı, patlayıcı ve elit kehribar aynı ekranda. | Faz 5.1 | Kolay — görsel |
| 4 | **Son iki boss duvar mı, tıkanma mı?** Hasar tavanı 5. bossta doluyor, sonra boss HP %52 artıyor. | Faz 6.2 | Orta — boss HP eğrisi |
| 5 | **Sektör 6-7 baskı hissettiriyor mu?** `descent_scale` ölüydü, baskı satır doluluğu ve saldırgan sıklığına taşındı. Fark hissediliyor mu, yoksa gürültü mü? | Faz 5.3 | Kolay — iki sayı |
| 6 | **İkinci yarı artık ödüllendirici mi?** Önce depth 40-48 arası sıfır level-up veriyordu. | Faz 6.1 | Kolay — tek eğri |
| 7 | **Zincir şimşeği ne kadar katkı veriyor?** Faz 7.1'de kart ona bağlandı ve bu bir buff. Temizleme hızı sınırımda hesaba katılmamıştı. | Faz 7.1 | Orta |

#### Bunlardan hangisi 25F'i gerçekten değiştirir

**1 ve 2 kritik.** İkisi de "oyun oynanabilir mi" sorusu. Yanlışsalar tek
sabit değişikliğiyle düzelir ama bilinmeden dondurulamaz.

**4 ve 7 birbirine bağlı.** Zincir şimşeği beklediğimden çok katkı
veriyorsa, boss duvarı sorun olmayabilir. İkisini ayrı ayrı değerlendirmek
yanıltır.

**3, 5, 6 his sorusu.** Tek run yeterli, ve cevap "evet/hayır"dan çok
"fark ettim mi" olur.

#### Ascension ayrı bir oturum istiyor

Yukarıdaki 2. madde ve Faz 6.2'nin tamamı ascension'a bağlı, ve
**ascension normal oynanışta görünmüyor** (bkz. 7.5). Test etmek için
`Shift+G` → `K` ile zafer tetiklenmeli, sonra menüden ascension seçilmeli.

Bu, "bir run oyna" isteğinin kapsamı dışında. Ascension dengesine
bakılacaksa ikinci bir oturum gerekiyor.

### Test kapsamı — neyin korunduğu

gdUnit4 kuruldu (`addons/gdUnit4`, v6.2.1). **54 test, hepsi geçiyor.**

```bash
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ --ignoreHeadlessMode
```

| Paket | Test | Korunan ölçüm |
|---|---|---|
| `elite_bricks_test` | 7 | Faz 5.1 elit oran ve can eğrisi |
| `sector_modifiers_test` | 6 | Faz 4.3 + 5.3 sektör modifier'ları |
| `curses_test` | 5 | Faz 4.2 lanet bedel/ödül dengesi |
| `progression_test` | 10 | Faz 5.2, 5.3, 6.1, 6.2 hata düzeltmeleri |
| `boss_scaling_test` | 6 | Faz 6.2 + 7.4 boss HP ölçeklemesi |
| `combo_chain_test` | 5 | Faz 7.1 kombo kartı → zincir şimşeği bağı |
| `colony_effects_test` | 5 | Faz 7.3 koloni tek kaynak |
| `documented_numbers_test` | 4 | Belgelerdeki sayılar koda karşı doğrulanır |
| `throughput_test` | 6 | Faz 6.4 türetilmiş değerler (9.2 tuğla/sn, 12.3 dk) |

**Henüz korunmayan:**

- Faz 6.1'in XP eğrisi tam olarak değil, yalnızca derinlik çarpanı
- Silah davranışları (Codex bölgesi)

**Türetilmiş değerler artık korunuyor.** `throughput_test` "9.2 tuğla/sn"
ve "~12.3 dakika" gibi *hesaplanan* sayıları canlı sabitlerden yeniden
kuruyor. 25F sırasında `minimum_safe_step_interval` ya da iniş eğrisi
değişirse test kırılıyor ve **yeni değeri söylüyor**. Doğrulandı: tabanı
0.45'ten 0.30'a çekince test "kod şimdi 9.9 veriyor" dedi.

**Testin sınırı:** bunlar denge sayılarını koruyor, oynanışı değil.
"Derinlik 32'de yetişilebiliyor mu" sorusunun cevabı testten çıkmaz,
oyun testinden çıkar.

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
