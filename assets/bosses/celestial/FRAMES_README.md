# THE CELESTIAL - kare dosyalari

Bu kareler `Gemini_Generated_Image_nue7tynue7tynue7.jfif` (3168x1312)
sprite sheet'inden otomatik kesildi. `boss_celestial.gd` klasoru calisma
aninda tarar; `idle_a.png` yoksa sahnedeki procedural kristal gorseline
duser ve oyun yine calisir.

| Dosya                | Sheet karsiligi | Poz     |
|----------------------|-----------------|---------|
| `idle_a.png`         | IDLE_A          | idle    |
| `idle_b.png`         | IDLE_B          | idle    |
| `attack_charge.png`  | ATTACK_CHARGE   | charge  |
| `attack_release.png` | ATTACK_RELEASE  | release |
| `hit_a.png`          | HIT_A           | hit     |
| `hit_b.png`          | HIT_B           | hit     |
| `defeat_a.png`       | DEFEAT_A        | defeat  |

## Oynatma

Kareler AnimatedSprite2D ile sert kesmeyle oynatilmiyor. Sahnede ust uste
iki Sprite2D katmani (`PoseA` / `PoseB`) var ve `boss_celestial.gd` bunlar
arasinda capraz gecis yapiyor:

- **idle**: iki kare arasinda kesintisiz gidip gelme (cos egrisi), kesme yok
- **charge**: idle'dan 0.20 sn'de yumusak gecis + artan titreme
- **release / hit**: 0.025-0.03 sn'de keskin gecis - darbe ani yumusatilirsa
  vurus koreliyor ve farkli siluetler hayal goruntu birakiyor
- **hit -> idle**: 0.18 sn yumusak donus

Uzerine prosedural hareket biniyor (suzulme, nefes, kaydigi yone yatma,
ates sonrasi geri tepme, hasarda savrulma). Kareleri degistirsen bu
katman aynen calisir.

## Nasil kesildi

1. Arka plan: kenarlardan **floating-range flood fill** (tolerans 6).
   Nebula yumusak gecisli oldugu icin flood yayilir, karakterin sert
   koyu konturunda durur. Esik/renk tabanli yontemler nebulayi ayiramadi.
2. Kopuk parcalar (HIT_A'nin firlayan yumrugu, DEFEAT_A'nin kristal
   kirintilari) korundu: en buyugun %3'unden buyuk her bilesen tutuluyor.
3. Siluetin icine hapsolmus koyu uzay cepleri (yalnizca ATTACK_RELEASE'te
   olusuyor) `fill_holes` sonrasinda ayrica temizlendi.
4. ATTACK_RELEASE'in dev dikey isini kadraj disinda birakildi - o isini
   oyun kendisi cizer (konumu paddle'a gore dinamik). Elde kalan kisa
   simsek kivilcimlari namlu parlamasi olarak duruyor.

## Hizalama - onemli

Butun kareler **gogus cekirdegi tam goruntu merkezinde** olacak sekilde
680x580 ortak tuvale oturtuldu, sonra %50 kucultuldu: **340x290**.

Bu yuzden `boss_celestial.gd` icinde:

- `CORE_LOCAL = (0, 0)` - zayif nokta sprite'in merkezi
- `CORE_HIT_RADIUS = 34` - cift hasar alan bolge
- `TARGET_SPRITE_HEIGHT = 200` - kare yuksekligi otomatik bu degere olceklenir
- Carpisma kutusu `180x180`

Kareleri yeniden uretirsen ayni hizalamayi koru, yoksa zayif nokta
gorselle ortusmez. Olcegi elle kontrol etmek istersen sahnedeki
`sprite_scale_override` degerini 0'dan buyuk yap.
