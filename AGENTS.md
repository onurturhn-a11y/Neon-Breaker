# Neon Break — İki Ajanlı Çalışma Kuralları

> `AGENTS.md` (Codex) ve `CLAUDE.md` (Claude) **aynı içeriktedir**.
> Birini değiştirirsen diğerini de değiştir.

**Depo:** https://github.com/onurturhn-a11y/Neon-Breaker

Bu projede iki geliştirici, iki farklı AI ajanıyla paralel çalışıyor:

- **Codex** → silah sistemi ve mobil kontroller
- **Claude** → zorluk, sektör, meta ilerleme, koloni

---

## 0. HER OTURUMDA İLK İŞ — atlanamaz

Kod yazmadan, dosya okumadan, plan yapmadan **önce** depoyu senkronla:

```bash
git fetch origin
git status
git log --oneline HEAD..origin/main
```

- `origin/main` ilerlemişse **önce güncelle**, sonra çalışmaya başla:
  ```bash
  git pull --rebase origin main
  ```
- Çakışma çıkarsa **çözmeye çalışma** — kullanıcıya söyle, onay bekle.
- Karşı ajanın ne yaptığını görmek için son commit'leri oku:
  ```bash
  git log --oneline -10 origin/main
  ```

**Neden:** iki ajan aynı anda çalışıyor. Senkron olmadan yazılan her satır,
sonradan elle çözülecek bir çakışmadır. Bu adım atlanırsa geri kalan tüm
kurallar işe yaramaz.

Aynı şey iş bitiminde de geçerli — bitirdiğini push et, yerelde bırakma:

```bash
git push origin <dalin>
```

---

## 0.5. İKİNCİ İŞ — `ILETISIM.md` oku

İki geliştiricinin çalışma saatleri örtüşmüyor. Canlı konuşma yok, bu yüzden
**depo tek iletişim kanalı.** Senkrondan hemen sonra oku:

```bash
git log --oneline -3 -- ILETISIM.md
```

Karşı taraf sana bir şey yazmış olabilir: birleştirme talimatı, kodunda
bulunan bir hata, cevap bekleyen bir soru.

Dosyanın başında **AÇIK MADDELER** tablosu var — sana yazılmış cevaplanmamış
her şey orada. Mesaj geçmişini baştan okumana gerek yok.

**Oturum sonunda iki iş var, ikisi de atlanamaz:**

**1. Cevap ver.** Sana yazılmış cevaplanmamış bir `[SORU]`, `[EYLEM]` veya
`[HATA]` varsa oturumu **cevap vermeden kapatma.** Bu koşullu değil.
Üç geçerli cevap: *yaptım*, *yapmayacağım (gerekçesiyle)*, ya da *şimdi
yapamıyorum (neyi beklediğimi yazıyorum)*. **Reddetmek meşru bir cevaptır,
sessiz kalmak değil.** Cevapladığın satırı tablodan sil.

**2. Durumunu yaz.** Karşı tarafın bilmesi gerekenler:

- Ne bitirdin, ne yarım kaldı
- **Ortak dosyalarda neye dokundun** — karşı taraf çakışmayı önceden görsün
- Bölge dışında bulduğun hata (düzeltme — bildir, bkz. bölüm 2)
- Karşı taraftan beklediğin bir şey → tabloya da ekle

Etiketler ve şablon `ILETISIM.md`'nin başında.

**Neden:** karşı ajan sen çalışırken uyuyor. Sorduğun soruya anında cevap
gelmeyecek, senin sorduğun da öyle. Bu yüzden iki şey gerekiyor: mesaj cevap
beklemeden ilerlenebilecek kadar açık olmalı, **ve** açık kalan her madde
cevaplanmalı. Sessizlik karşı tarafı ya bekletir ya da yanlış varsayımla
ilerletir — ikisi de sonradan elle çözülecek bir çakışmaya döner.

---

## 1. Bölge sahipliği

| Bölge | Dosyalar |
|---|---|
| **CODEX** | `arc_cannon_controller.gd`, `scatter_cannon_controller.gd`, `railgun_controller.gd`, `homing_missile*.gd/tscn`, `pulse_laser_*.gd`, `scatter_projectile.gd/tscn`, `weapon_targeting.gd`, `*_visual.gd` (silah görselleri), `paddle.gd`, `plasma_bullet.gd`, `mobile_paddle_controls.gd` |
| **CLAUDE** | `continuous_brick_field.gd`, `level_generator.gd`, `side_attacker_spawner.gd`, `combo_manager.gd`, `colony.gd`, `boss_*.gd` |
| **ORTAK** | `main.gd`, `game_manager.gd`, `card_pool.gd`, `card_system.gd`, `weapons/`, `main.tscn`, `ball.gd`, `build_hud.gd` |

---

## 2. Bölge dışında hata görürsen

1. **DÜZELTME.** Dosyaya dokunma.
2. Bulguyu bildir — GitHub issue veya PR yorumu.
3. Kullanıcıya söyle ve **onayını bekle.**

Düzeltmenin doğru olduğundan emin olsan bile geçerlidir. İki ajanın aynı
dosyayı düzeltmesi, düzeltilen hatadan pahalıya patlar.

---

## 3. Ortak dosyalarda çalışma

- Sadece kendi özelliğinin gerektirdiği fonksiyonlara dokun.
- **Fonksiyon taşıma, yeniden adlandırma, blok yeniden sıralama YAPMA.**
  Çözülmesi en zor çakışmalar bunlardır.
- Yeni kod eklerken dosyanın sonuna değil, ilgili bölümün yanına ekle.

### Genişletme noktaları — ortak dosyaya dokunmadan iş yapmanın yolu

| Ne eklemek istiyorsun | Nereye yaz | `main.gd`'ye dokunman gerekir mi |
|---|---|---|
| Yeni silah kartı | `weapons/weapon_cards.gd` | Hayır |
| Silah davranışı | `weapons/weapon_system.gd` + kendi controller'ın | Hayır |
| Yeni pasif kart | `card_pool.gd` (`CARDS` sözlüğü) | Hayır |
| Kart teklif kuralı | `card_system.gd` | Hayır |

Silah seviyeleri `GameManager.weapon_slots` içinde tutulur (`card_levels`'ta
**değil**). Sorgular `GameManager.get_weapon_level()` üzerinden gider.

---

## 4. Godot kuralları

- `*.import` ve `*.uid` dosyaları **COMMIT EDİLİR.** Silme, ignore etme.
  Godot 4'te kaynak kimliğini taşırlar; kaybolursa karşı tarafta tüm sahne
  referansları kopar.
- `.godot/` **commit edilmez** (127 MB, makineye özel).
- **`main.tscn`'e yeni düğüm EKLEME.** Sahne çakışmaları pratikte çözülemez.
  Yeni UI'ı koddan üret — ödül banner'ı, boss ödül ekranı, reroll/banish
  butonları ve PARÇA sayacı bu yüzden koddan çiziliyor.
- **`static func` içinden autoload çağırma.** Godot, `class_name` script'lerini
  autoload'lar kaydolmadan derleyebiliyor; `GameManager` çağrısı
  "Identifier not found" verir. Bunun yerine parametre olarak geçir
  (`card_system.gd` ve `weapons/weapon_cards.gd` böyle yazılmıştır).
- Yeni asset eklerken import'u çalıştır:
  ```bash
  godot --headless --import --path .
  ```
- game-icons.net SVG'leri **beyaz dolgu + şeffaf arka plan** olmalı; siyah
  dolgu `modulate` ile renklendirilemez. Yeni ikon eklersen yazarını
  `CREDITS.md`'ye yaz (CC BY 3.0 atıf zorunluluğu).

---

## 5. PR öncesi zorunlu doğrulama

### Motor sürümü — 4.7 stable

Proje **Godot 4.7 stable** ile geliştiriliyor. Her iki geliştirici de aynı
minör sürümde olmalı; doğrulama da 4.7 ile yapılır.

> **Neden yazılı:** bir dönem üç sürüm aynı anda dolaştı — `project.godot`
> "4.8" diyordu, telefona 4.8.dev4 ile kuruluyordu, doğrulamalar 4.6 stable
> ile yapılıyordu. **Godot eski sürümü açarken uyarı vermiyor**, yani yanlış
> motorla test etmek sessizce mümkün.
>
> `project.godot` içindeki `config/features = ("4.8", "Mobile")` etiketi
> **gerçek bir bağımlılık değil** — projeyi ilk kuran editörden kalma.
> Kanıtı: 4.7.2 projeyi hatasız koşuyor. 4.8'e özel bir şey kullanılsaydı
> koşmazdı. Dosya ilk baseline commit'inden beri hiç değişmedi, hiçbir
> editör onu yeniden yazmadı.

**Sürüm neden 4.7:** iki geliştiricinin farklı motorda olması, herhangi bir
dosya çakışmasından daha sinsi bir risktir — biri kaydettiğinde diğerinin
açamayacağı bir şey yazabilir. 4.7 ayrıca kararlı sürüm; 4.8 dev build.

```bash
godot --headless --quit-after 300 --path .
```

Çıktıda `SCRIPT ERROR` veya `Parse Error` **olmamalı.**
Çıkıştaki "ObjectDB instance leaked" uyarısı normaldir (zorla kapatma).

### Testler — gdUnit4

Test çerçevesi kurulu: `addons/gdUnit4` (v6.2.1). Testler `tests/` altında.

```bash
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ --ignoreHeadlessMode
```

`--ignoreHeadlessMode` gerekli: gdUnit4 headless modda UI girdisi
çalışmadığı için uyarı verip duruyor. Denge testleri girdi kullanmadığı
için bu uyarı bizi ilgilendirmiyor.

**Eklenti `project.godot`'ta etkinleştirilmedi** — CLI koşucusu buna
ihtiyaç duymuyor ve `project.godot`'a dokunmamak çakışma yüzeyini dar
tutuyor. Editör içi test denetçisini istersen kendin etkinleştir; o
değişikliği commit etme.

Üretilen `reports/` klasörü `.gitignore`'da.

**Ne test edilir:** denge sayıları. Faz 4-7'de birçok sabit ölçümle
seçildi; test onların sessizce bozulmasını engeller. Geçici sondalar
hâlâ `_` önekiyle yazılır ve depoya girmez — kalıcı olması gereken ölçüm
`tests/` altına test olarak yazılır.

**Eklenti kurarken:** her eklentinin Godot sürüm uyumunu ayrı kontrol et.
Kurduğun eklentiyi `ILETISIM.md`'ye yaz — `addons/` klasörü iki ajan için
yeni bir çakışma yüzeyidir.

Geçici test scriptleri `_` ile başlamalı (`_my_test.gd`) — `.gitignore`'da,
depoya girmez.

---

## 6. Dal düzeni

- `main` — korumalı. Doğrudan yazılmaz.
- `feat/<konu>` — her iş kendi dalında.

Birleştirme yalnızca PR ile, karşı tarafın onayıyla.

---

## 7. Proje durumu

> Son güncelleme: 2026-08-30. Faz 6 sonu, PR #2-#4 birleşti.

**Tamamlanan:**
- Faz 1 — boş level-up hatası, boss ödülü, kalıcı rekorlar, ölü kod temizliği
- Faz 2 — veri odaklı kart havuzu, nadirlik, reroll/banish, boss ödül seçim
  ekranı, delici evrimi
- Faz 3 — boss HP ölçeklemesi, sonsuz koloni kalibrasyonu, 9 bina/6 platform,
  raket kimlikleri
- Faz 4 (Claude) — build cezası kaldırıldı, sektör modifier'ları, lanet
  sistemi, kasa, zafer ekranı, ascension
- Faz 5 (Claude) — elit tuğla, iniş hızı doygunluğu, koloni tavanı denetimi
- Faz 6 (Claude) — ilerleme eğrisi, ascension hasar tavanı, tehlike hattı
  ekonomisi
- Codex — 7 silah + plazma (Arc Cannon, Scatter Cannon, Railgun, Homing
  Missile, Pulse Laser, Mine Launcher, Mortar), 2 yuvalı silah sistemi,
  `ensure_runtime_controller` kancası, rastgele kart eli, mobil kontroller

Kart havuzu: **22 kart** (14 pasif + 8 silah).

**Run yapısı (ölçüldü):** depth 1 → 56, 7 boss (depth 8, 16, 24, 32, 40, 48,
56). Tuğla inişi ~12.3 dakika, boss dövüşleri hariç. Bir run 21 kart seçimi
veriyor; havuz kapasitesi 58.

**Sıradaki:** görev dağılımı `GOREVLER.md`, mesajlaşma `ILETISIM.md`.
- Codex → görsel açık (8 silahın 7'si aynı iki kartı kullanıyor), Krediler
  ekranı, kalan iki silah
- Claude → Faz 7: ölçülmemiş sistemler (kombo, koloni ekonomisi)

**Oyun testi bekliyor.** Faz 6'da üç sayı ölçümle değil tahminle seçildi ve
oyun testi olmadan doğrulanamaz:
- Derinlik 32+ için gereken 9.2 tuğla/sn tutturulabiliyor mu
- Ascension 10'un iniş tabanı (0.368s) oynanabilir mi
- Elit tuğla çerçevesi diğer özel tuğlalardan ayırt ediliyor mu

**Açık konular:**
- `CREDITS.md` — 8 ikonun yazarı doğrulanmalı
- Oyun içi "Krediler" ekranı yok (CC BY 3.0 gereği)
- `assets/_archive/` (35 MB) depoya alınmadı; silinecek mi karar verilmeli
- `RARITY_LEGENDARY` tanımlı ama `get_rarity_weight()`'te karşılığı yok
- `xp_orb.gd` / `xp_orb.tscn` ölü kod
- `main.gd` debug tuşları `OS.is_debug_build()` ile korunmuyor
