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

> **Birleştirme sonrası `GdUnitTestCIRunner` bulunamadı hatası alırsan**
> sınıf önbelleği bayatlamıştır. `addons/` değişen her birleştirmeden
> sonra olabilir:
>
> ```bash
> rm .godot/global_script_class_cache.cfg
> godot --headless --import --path .
> ```

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
- Codex — 8 silah + plazma (Arc Cannon, Scatter Cannon, Railgun, Homing
  Missile, Pulse Laser, Mortar, Drone Bay, Orbital Strike), 2 yuvalı silah
  sistemi, `ensure_runtime_controller` kancası, rastgele kart eli, mobil
  kontroller, 20 kartlık görsel seti

Kart havuzu: **19 kart** (10 pasif + 9 silah). Mine Launcher kaldırıldı,
yerine Drone Bay ve Orbital Strike geldi.

**Run yapısı (ölçüldü):** depth 1 → 60, **10 boss** (depth 6, 12, 18, 24, 30,
36, 42, 48, 54, 60). Tuğla inişi **~13.1 dakika**, boss dövüşleri hariç
(Faz 9'da yeniden ölçüldü; 7 bossluk yapıda 12.3 dakikaydı, +%6.5).
Kartların havuz kapasitesi 51.

> **Yeniden ölçülmesi gereken:** "bir run 21 kart seçimi veriyor" sayısı
> 7 bossluk yapıda ölçülmüştü. Run uzadı ve boss ödülü 7'den 10'a çıktı,
> yani bu sayı artık yanlış — ama tahminle değiştirmedim, oyun testiyle
> ölçülmeli. Aynı şekilde boss ödül ekonomisi: run başına toplam PARÇA
> 100 → 192, coin 61 → 125 (yarısı boss sayısından, yarısı ödül dizisinin
> tamamının kullanılır hale gelmesinden). `GOREVLER.md` 6.2 kalemi.

**Sıradaki:** görev dağılımı `GOREVLER.md`, mesajlaşma `ILETISIM.md`.

- **Codex** → Krediler ekranı, ikon yazarlarının doğrulanması
- **Claude** → Faz 9: boss kadrosu 7 → 10

Faz 4-7'de ölçülebilir olan ölçüldü ve 56 testle korumaya alındı. Kalan
yedi soru tabloyla değil oynanışla cevaplanıyor (`GOREVLER.md` → "25F
için"); **Faz 8 = oyun testi sonrası kalibrasyon** hâlâ o cevapları
bekliyor.

### Faz 9 — boss kadrosu 7 → 10 (Onur talimatı, 2026-08-31)

25F feature freeze **bu iş için kaldırıldı.** Üç yeni boss eklendi; üçü de
mevcut yedinin kullanmadığı bir mekanik fiil üstüne kurulu, çünkü yedinin
beşi aynı şeyi yapıyordu (telegraf edilen bölgeden kaç).

| Boss | HP | Fiil |
|---|---|---|
| THE HARVESTER | 175 | Tuğla sahasını yer, zırha çevirir — yem/takas |
| THE CHORUS | 5×58 | Beş gövde, ölen her üye kalanı hızlandırır — hedef seçimi |
| THE INVERSION | 455 | Kendi ateşini geri döndürür — ateş kesme testi |

HP değerleri mevcutların **arasına** giriyor (100, 145, *175*, 200, 260,
*290*, 330, 410, *455*, 500), yani yedi bossun hiçbir sayısı değişmedi.

**Bitti — üç yeni boss.** Kare setleri kesildi, üç script + sahne yazıldı,
debug tuşları açıldı (`Y` / `U` / `I`), ve **ilerleme akışına bağlandılar**:
boss aralığı 8'den 6'ya indi, kadro derinlik 6…60 arasında on boss.

**Bitti — ilk iki boss yenilendi.** THE CORE ve THE SENTINEL tek düz PNG
kullanıyordu; **THE FURNACE** (diyafram) ve **THE WARDEN** (omuzdaki iki
jeneratör) olarak yeniden tasarlandılar. İkisi de `StaticBody2D`'den
`boss_sprite_entity.gd`'ye taşındı. **Artık on bossun hepsi tek mimariden
türüyor ve hepsi sprite sheet kullanıyor** — bölüm 7'deki eski "iki mimari"
notu kapandı. Boss id'leri değişmedi (`&"core"`, `&"sentinel"`).

**Ölçüldü:** tuğla inişi 12.3 → **13.1 dakika** (+%6.5). Boss ödül dizileri
zaten 10 elemanlıydı, kadro 10 olunca tamamı kullanılır hale geldi: run
başına PARÇA 100 → **192**, coin 61 → **125**.

**Bitmedi — oyun testi.** Üç şey ölçülmedi:
- Yeni üç bossun mekanikleri oynanışta gerçekten okunuyor mu
- Ödül ekonomisinin iki katına çıkması koloniyi ve silah kilit açma
  dükkânını bozuyor mu (`ILETISIM.md` A14/A16)
- Belgedeki "bir run 21 kart seçimi veriyor" sayısı 7 bossluk yapıda
  ölçülmüştü, artık yanlış — tahminle değiştirilmedi

**Bitmedi — Mortar.** `mortar_shell.gd` hiçbir gruba girmediği için THE
INVERSION'ın ayna bandından muaf. Codex bölgesi, `ILETISIM.md` A13.

**Oyun testi bekliyor.** Faz 6'da üç sayı ölçümle değil tahminle seçildi ve
oyun testi olmadan doğrulanamaz:
- Derinlik 32+ için gereken 9.2 tuğla/sn tutturulabiliyor mu
- Ascension 10'un iniş tabanı (0.368s) oynanabilir mi
- Elit tuğla çerçevesi diğer özel tuğlalardan ayırt ediliyor mu

**Açık konular** (hepsi Codex'te ya da karar bekliyor —
`ILETISIM.md` açık maddeler tablosunda takip ediliyor):

- `CREDITS.md` — 8 ikonun yazarı doğrulanmalı
- Oyun içi "Krediler" ekranı yok (CC BY 3.0 gereği, tek hukuki kalem)
- `RARITY_LEGENDARY` tanımlı ama `get_rarity_weight()`'te karşılığı yok
  → teklif ağırlığı 1.0'a düşüyor, yaygının 1/45'i
- `xp_orb.gd` / `xp_orb.tscn` ölü kod — `main.gd` `exp_orb.tscn` yüklüyor
  ama değişken adı `xp_orb_scene`, okuyanı yanıltıyor
- Faz 6.2 kararı yarım: ascension hasar tavanı açıldı (pasif kartlar),
  silah tarafı (3. yuva) Codex'in cevabını bekliyor

> `assets/_archive/` maddesi kaldırıldı: bu makinede de depoda da yok,
> `.gitignore`'da da geçmiyor. Karşı tarafın diskinde duruyorsa orada
> karar verilir; bu deponun sorunu değil.
