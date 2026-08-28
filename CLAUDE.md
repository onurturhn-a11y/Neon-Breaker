# Neon Break — İki Ajanlı Çalışma Kuralları

> Bu dosya ile `AGENTS.md` **aynı içeriktedir**. Birini değiştirirsen
> diğerini de değiştir, yoksa iki ajan farklı kurallara göre davranır.

Bu depoda iki AI ajanı paralel çalışıyor:

- **Codex** → silah / yuva sistemi
- **Claude** → zorluk, sektör, meta ilerleme

Temel kural: **kendi bölgen dışına yazma.**

---

## Bölge sahipliği

| Bölge | Dosyalar |
|---|---|
| **CODEX** | `weapons/`, `paddle.gd`, `plasma_bullet.gd`, `paddle_weapon_visual.gd` |
| **CLAUDE** | `continuous_brick_field.gd`, `level_generator.gd`, `side_attacker_spawner.gd`, `combo_manager.gd` |
| **ORTAK** | `main.gd`, `game_manager.gd`, `card_pool.gd`, `card_system.gd`, `main.tscn`, `colony.gd`, `ball.gd` |

---

## Bölge dışında hata görürsen

1. **DÜZELTME.** Dosyaya dokunma.
2. Bulguyu bildir:
   ```bash
   gh issue create --title "..." --body "..."
   ```
   `gh` yoksa PR yorumu olarak bırak.
3. Kullanıcıya söyle ve **onayını bekle.**

Bu kural, düzeltmenin doğru olduğundan emin olsan bile geçerlidir.
İki ajanın aynı dosyayı düzeltmesi, düzeltilen hatadan daha pahalıya patlar.

---

## Ortak dosyalarda çalışma

- Sadece kendi özelliğinin gerektirdiği fonksiyonlara dokun.
- **Fonksiyon taşıma, yeniden adlandırma veya blok yeniden sıralama YAPMA.**
  Bunlar çözülmesi en zor birleştirme çakışmalarını üretir.
- Yeni kod eklerken dosyanın sonuna değil, ilgili bölümün yanına ekle.
- Yazmadan önce daima senkron ol:
  ```bash
  git pull --rebase origin main
  ```

---

## Godot kuralları

- `*.import` ve `*.uid` dosyaları **COMMIT EDİLİR.** Silme, `.gitignore`'a ekleme.
  Godot 4'te kaynak kimliğini taşırlar; kaybolursa karşı tarafta tüm sahne
  referansları kopar.
- `.godot/` **commit edilmez** (127 MB, makineye özel).
- **`main.tscn`'e yeni düğüm EKLEME.** Sahne dosyası çakışmaları pratikte
  çözülemez. Yeni UI'ı koddan üret — mevcut ödül banner'ı, boss ödül ekranı,
  reroll/banish butonları ve rekor satırı bu yüzden koddan çiziliyor.
- Yeni asset eklerken import'u çalıştır:
  ```bash
  godot --headless --import --path .
  ```
- game-icons.net SVG'leri **beyaz dolgu + şeffaf arka plan** olmalı.
  Siyah dolgu `modulate` ile renklendirilemez. Yeni ikon eklersen
  `CREDITS.md`'ye yazarını da ekle (CC BY 3.0 atıf zorunluluğu).

---

## PR öncesi zorunlu doğrulama

```bash
godot --headless --quit-after 300 --path .
```

Çıktıda `SCRIPT ERROR` veya `Parse Error` **olmamalı.**
Çıkıştaki "ObjectDB instance leaked" uyarısı normaldir (zorla kapatmadan kaynaklanır).

Geçici test scriptleri `_` ile başlamalı (`_my_test.gd`) — bunlar
`.gitignore`'da, depoya girmez.

---

## Dal düzeni

- `main` — korumalı. Doğrudan yazılmaz.
- `feat/weapon-mounts` — Codex
- `feat/difficulty` — Claude

Birleştirme yalnızca PR ile, karşı tarafın onayıyla.

---

## Proje durumu

Faz 1–3 tamamlandı: kart havuzu (15 kart, nadirlik, reroll/banish), boss ödül
seçim ekranı, kalıcı rekorlar, sonsuz koloni kalibrasyonu, raket kimlikleri,
boss HP ölçeklemesi.

Sıradaki iş: Codex → silah yuva sistemi · Claude → Faz 4 (zorluk dengesi,
risk mekanikleri, sektör modifier'ları, ascension).
