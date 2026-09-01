# THE HARVESTER - kare dosyalari

Kaynak: `Harvester.jpg` (2816x1536), tek sheet.
Uretim prompt'u ve saldiri paterni tasarimi: boss kadrosu tasarim notu
(GOREVLER.md / ILETISIM.md uzerinden ulasilir).

| Dosya | Sheet karsiligi | Kullanim |
|---|---|---|
| `idle_a.png` | 1. kare | idle |
| `idle_b.png` | 2. kare | idle |
| `attack_charge.png` | 3. kare | hasat sarji (kollar yukarida) |
| `attack_release.png` | 5. kare | hasat (tuglalar gogse cekiliyor) |
| `charge_2.png` | 7. kare | kusma sarji (tugla omuzda) |
| `release_2.png` | 8. kare | kusma atisi (iz ile) |
| `hit_a.png` | 9. kare | hasar |
| `hit_b.png` | 10. kare | hasar (plakalar dokuluyor) |
| `defeat_a.png` | 11. kare | yenilgi |

Sheet 9 yerine **11 poz** ile geldi ve etiketsizdi; esleme goze gore
yapildi ve **Onur tarafindan onaylandi (2026-08-31)**. Kullanilmayan iki
fazla poz `alt_grab.png` (4. kare) ve `alt_lift.png` (6. kare) olarak
saklandi — silinmedi, ileride poz degistirmek istenirse oradan alinir.

Mermi dokusu ayrica uretilmedi. Efektlerin tamami kodda ciziliyor
(`_add_gradient_band`, `_column_polygon`, `_apply_additive`); mermi
`apply_palette()` ile calisma aninda yeniden renklendiriliyor.

## Kesim — duz magenta zemin

Sheet duz tek renk zemin uzerinde geldi (saf magenta #FF00FF). Onceki sheet'lerdeki dama
zemini sorunu yok; kesim tek asamali:

1. **Renk anahtari** — R>185 ve B>185 ve G<130 olan piksel zemin.
2. **Ic bolgede alfa 1'e zorlandi** (2 piksel erozyon). Yalniz sinir
   bandinda yumusak alfa var; zemin katkisi renkten sadece o bantta geri
   cikarildi (`C = (gozlenen - (1-alfa)*zemin) / max(alfa, 0.35)`).
   Bu adim atlanirsa dusuk doygunluklu bolgeler (yenilgi karesinin grisi)
   zemin cikarma yuzunden renk kaydiriyor.
3. **Kol-govde bosluklari** — delik doldurma sonrasi hala zemin renginde
   kalan pikseller yeniden seffaflastirildi; yoksa kolun altindaki gercek
   bosluk opak siyah doluyor.

4. **Magenta sizinti onarimi** — bu bossun paletinde magenta YOK, dolayisiyla
   magentaya calan her piksel zemin sizintisidir. Parlayan bolgelerde
   (tuglanin halesi, duman, hareket izi) kalan mor hale bu kuralla
   notrlendi.

## Hizalama

Ortak capa: **gogus maw'inin merkezi**. Tum karelerde ayni piksel koordinatinda; boss poz
degistirirken ziplamasin diye kareler tek tek bu noktaya gore ortalandi.
Kesim sonrasi %50 kucultuldu (void_sovereign ile ayni konvansiyon).

Tuval: **418x301**.
`boss_harvester.gd`: `_get_target_sprite_height()` = 215.0.
