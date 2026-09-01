# THE CHORUS - kare dosyalari

Kaynak: `Chorus.jpg` (2816x1536), tek sheet.
Uretim prompt'u ve saldiri paterni tasarimi: boss kadrosu tasarim notu
(GOREVLER.md / ILETISIM.md uzerinden ulasilir).

| Dosya | Sheet karsiligi | Kullanim |
|---|---|---|
| `idle_a.png` | IDLE_A | idle |
| `idle_b.png` | IDLE_B | idle |
| `attack_charge.png` | ATTACK_CHARGE | nota sarji |
| `attack_release.png` | ATTACK_RELEASE | nota atisi |
| `hit_a.png` | HIT_A | hasar |
| `hit_b.png` | HIT_B | hasar |
| `defeat_a.png` | DEFEAT_A | yenilgi |
| `duet_a.png` | DUET | iki uye birlesmis hali |

`duet_a.png` taban sinifin kare sozlugunde yok. `_get_frame_sets()` ezilip
`sets[&"duet"] = ["duet_a.png"]` eklenmeli.

Sheet'te etiketler ve hucre cizgileri karenin icine basilmisti; satir
bantlari ayrilirken etiket seridi disarida birakildi.

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

**Bilinen artiklar:**
- `attack_release` karesinde notanin kendisi de cizilmis durumda. Kod ayrica
  mermi uretecegi icin ilk atista iki nota gorunur. Rotus yapilacaksa
  oradan baslanmali.
- `defeat_a` karesinde girtlak sondugu icin otomatik capa bulunamadi;
  kukuletanin ust %25'inin x merkezine gore yerlestirildi.
- Karakter olcegi kareler arasinda bir miktar oynuyor (uretimden geliyor);
  poz degisiminde hafif buyuyup kuculme okunur.

## Hizalama

Ortak capa: **girtlak yariginin merkezi**. Tum karelerde ayni piksel koordinatinda; boss poz
degistirirken ziplamasin diye kareler tek tek bu noktaya gore ortalandi.
Kesim sonrasi %50 kucultuldu (void_sovereign ile ayni konvansiyon).

Tuval: **285x335**.
`boss_chorus.gd`: `_get_target_sprite_height()` = 96.0.
