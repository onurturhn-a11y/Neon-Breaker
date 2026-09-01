# THE INVERSION - kare dosyalari

Kaynak: `Inversion.jpg` (2816x1536), tek sheet.
Uretim prompt'u ve saldiri paterni tasarimi: boss kadrosu tasarim notu
(GOREVLER.md / ILETISIM.md uzerinden ulasilir).

| Dosya | Sheet karsiligi | Kullanim |
|---|---|---|
| `idle_a.png` | IDLE_A | idle |
| `idle_b.png` | IDLE_B | idle |
| `attack_charge.png` | ATTACK_CHARGE | ayna bandi sarji |
| `attack_release.png` | ATTACK_RELEASE | band bosalmasi |
| `charge_2.png` | CHARGE_2 | ikinci duzlem sarji |
| `release_2.png` | RELEASE_2 | ikinci duzlem acilmasi |
| `hit_a.png` | HIT_A | hasar |
| `hit_b.png` | HIT_B | hasar |
| `defeat_a.png` | DEFEAT_A | yenilgi |

Sheet'te `CHARGE_2` iki kez basilmis (5. ve 6. hucre). 5. hucre kullanildi;
6. hucre `alt_charge_2.png` olarak saklandi.

`ATTACK_CHARGE` karesinde kollar govdeden ayrik geldigi icin sutun
ayirmada uc parcaya bolunuyordu; uc parca tek figur olarak birlestirildi.

Mermi dokusu ayrica uretilmedi. Efektlerin tamami kodda ciziliyor
(`_add_gradient_band`, `_column_polygon`, `_apply_additive`); mermi
`apply_palette()` ile calisma aninda yeniden renklendiriliyor.

## Kesim — duz magenta zemin

Sheet duz tek renk zemin uzerinde geldi (soluk orkide ~#AC77B2 (istenen duz magenta gelmedi)). Onceki sheet'lerdeki dama
zemini sorunu yok; kesim tek asamali:

1. **Renk anahtari** — zemin rengine mesafe **ve** doygunluk birlikte olculdu. Tek hue esigi
   yetmiyor: karakterin alt yarisi da magenta ailesinde. Ayirici doygunluk —
   zemin donuk (sat<0.46), karakterin magentasi doygun.
2. **Ic bolgede alfa 1'e zorlandi** (2 piksel erozyon). Yalniz sinir
   bandinda yumusak alfa var; zemin katkisi renkten sadece o bantta geri
   cikarildi (`C = (gozlenen - (1-alfa)*zemin) / max(alfa, 0.35)`).
   Bu adim atlanirsa dusuk doygunluklu bolgeler (yenilgi karesinin grisi)
   zemin cikarma yuzunden renk kaydiriyor.
3. **Kol-govde bosluklari** — delik doldurma sonrasi hala zemin renginde
   kalan pikseller yeniden seffaflastirildi; yoksa kolun altindaki gercek
   bosluk opak siyah doluyor.

**Bilinen artiklar:**
- `attack_release` pozu `idle_a`'ya fazla benziyor; kollar yeterince
  asagi-iceri kapanmamis. Saldiri poz olarak zayif okuyacak.
- `defeat_a` karesinde dikis sondugu icin otomatik capa bulunamadi;
  govdenin ust %25'ine gore yerlestirildi.

## Hizalama

Ortak capa: **ayna dikisi (en parlak yatay beyaz satir)**. Tum karelerde ayni piksel koordinatinda; boss poz
degistirirken ziplamasin diye kareler tek tek bu noktaya gore ortalandi.
Kesim sonrasi %50 kucultuldu (void_sovereign ile ayni konvansiyon).

Tuval: **276x346**.
`boss_inversion.gd`: `_get_target_sprite_height()` = 275.0.
