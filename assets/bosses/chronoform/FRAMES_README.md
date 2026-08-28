# THE CHRONOFORM - kare dosyalari

Kaynak: `Gemini_Generated_Image_lgwxlelgwxlelgwx.jfif` (3168x1312),
`VOID_SPLICER_CHRONO_FORMER_BOSS_LEVEL_7_SPRITE_SHEET_V5.0`.

| Dosya             | Sheet karsiligi    | Kullanim              |
|-------------------|--------------------|-----------------------|
| `idle_a.png`      | IDLE_A             | idle                  |
| `idle_b.png`      | IDLE_B             | idle                  |
| `charge.png`      | ATTACK_1_CHARGE    | supurge sarji         |
| `release.png`     | ATTACK_1_RELEASE   | supurge atisi         |
| `charge_2.png`    | ATTACK_2_CHARGE(2) | duvar sarji           |
| `release_2.png`   | ATTACK_2_CHARGE(1) | duvar atisi (kasirga) |
| `hit_a.png`       | HIT_B              | hasar                 |
| `defeat_a.png`    | DEFEAT_B           | yenilgi               |
| `spike_burst.png` | ATTACK_2_RELEASE(2)| duvar karo dokusu     |
| `spike_shards.png`| PARTICLES_VOID_SPIKES | kiymiklar          |

Mermi dokusu URETILMEDI. Bu bossun runeleri zaten turuncu, THE CORE'un
varsayilan mermisi temaya birebir oturuyor; `_get_projectile_palette()`
bos dizi donduruyor ve varsayilan gorunum kullaniliyor.

## Kesim

5. ve 6. seviyeyle ayni dama zemini (kare 32 px, JPEG oldugu icin
gercek alfa yok). Ayni iki asamali anahtar: duz renk anahtari + yerel
dama genligi. Ayrintili aciklama:
`assets/bosses/void_sovereign/FRAMES_README.md`.

Bu sheet uc sheet arasinda en temiz cikani oldu - hale, artik ya da
yazi bulasmasi yok. Baslik/alt baslik/etiket bantlari yine kesimden
once zemin tonuyla boyandi.

## Hizalama

Bu boss insansi degil, radyal bir mandala. Ankor olarak gogus yerine
mandalanin parlak rune merkezi kullanildi (parlaklik agirlikli merkez).
548x534 tuvale oturtulup %50 kucultuldu: **274x267**.
`_get_target_sprite_height()` = 225.

`boss_chronoform.gd` ayrica taban sinifin `_update_pose_motion`'ini
genisletiyor: insansi bosslarin "kaydigi yone yatma" hareketi burada
anlamsiz oldugu icin mandala kendi ekseninde doniyor (saldiri
sirasinda 2.6 kat hizli).

## Duvar karolarina dair

`spike_burst.png` duvar boyunca doseniyor. Yatay olcek dokunun kendi
oranindan DEGIL, `WALL_TILE_WIDTH`'ten turetiliyor; yoksa karolar
birbirinin ustune tasip guvenli boslugu kapatiyor ve duvar kesintisiz
gorunuyor.
