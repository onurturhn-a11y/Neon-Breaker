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

```bash
godot --headless --quit-after 300 --path .
```

Çıktıda `SCRIPT ERROR` veya `Parse Error` **olmamalı.**
Çıkıştaki "ObjectDB instance leaked" uyarısı normaldir (zorla kapatma).

Geçici test scriptleri `_` ile başlamalı (`_my_test.gd`) — `.gitignore`'da,
depoya girmez.

---

## 6. Dal düzeni

- `main` — korumalı. Doğrudan yazılmaz.
- `feat/<konu>` — her iş kendi dalında.

Birleştirme yalnızca PR ile, karşı tarafın onayıyla.

---

## 7. Proje durumu

**Tamamlanan:**
- Faz 1 — boş level-up hatası, boss ödülü, kalıcı rekorlar, ölü kod temizliği
- Faz 2 — 15 kartlık veri odaklı havuz, nadirlik, reroll/banish, boss ödül
  seçim ekranı, delici evrimi
- Faz 3 — boss HP ölçeklemesi, sonsuz koloni kalibrasyonu, 9 bina/6 platform,
  raket kimlikleri
- Codex — 5 silah (Arc Cannon, Scatter Cannon, Railgun, Homing Missile,
  Pulse Laser), 2 yuvalı silah sistemi, mobil kontrol iyileştirmeleri,
  PARÇA HUD'u

Kart havuzu: **20 kart** (15 temel + 5 silah).

**Sıradaki:** görev dağılımı `GOREVLER.md` dosyasındadır.
- Codex → görsel üretim, metin/dil, kalan silahlar
- Claude → Faz 4: zorluk dengesi, risk mekanikleri, sektör modifier'ları,
  ascension

**Açık konular:**
- `CREDITS.md` — 8 ikonun yazarı doğrulanmalı, müzik lisansı netleşmeli
- Oyun içi "Krediler" ekranı yok (CC BY 3.0 gereği)
- `assets/_archive/` (35 MB) depoya alınmadı; silinecek mi karar verilmeli
