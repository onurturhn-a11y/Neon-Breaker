# THE VOID SOVEREIGN - kare dosyalari

Kaynak: `Gemini_Generated_Image_7ktcwh7ktcwh7ktc.jfif` (3168x1312),
`COSMIC_VOID_ENTITY_BOSS_LEVEL_5_SPRITE_SHEET_V2.0`.

| Dosya            | Sheet karsiligi   | Kullanim                |
|------------------|-------------------|-------------------------|
| `idle_a.png`     | IDLE_A            | idle                    |
| `idle_b.png`     | IDLE_B            | idle                    |
| `charge.png`     | ATTACK_1_CHARGE   | akinti sarji            |
| `release.png`    | ATTACK_1_RELEASE  | akinti atisi            |
| `charge_2.png`   | ATTACK_2_CHARGE   | diken sarji             |
| `release_2.png`  | ATTACK_2_RELEASE  | diken atisi             |
| `hit_a.png`      | HIT_B             | hasar                   |
| `defeat_a.png`   | DEFEAT_B          | yenilgi                 |
| `spike_burst.png`| ATTACK_2_RELEASE  | dikenlerin efekt dokusu |
| `spike_shards.png`| PARTICLES_VOID_SPIKES | diken kiymiklari   |

Mermi dokusu ayrica uretilmedi; `assets/bosses/void/shard_projectile.png`
ayni temada oldugu icin paylasiliyor.

## Kesim - dama zemini

Bu sheet oncekilerden farkli olarak dama deseni uzerinde geldi, ama
**JPEG oldugu icin gercek alfa yok** - dama piksel olarak basili.
Kare 32 px, iki ton ~190/230.

Iki asamali anahtar kullanildi:

1. **Duz renk anahtari** - parlak VE doygunlugu dusuk pikseller zemin.
   Tek basina yetmedi: karakterin yari saydam dis parlamasi zeminle
   karisinca acik bir hale birakti.
2. **Desen anahtari** - dama duzenli oldugu icin altta kalip kalmadigi
   YEREL DESEN GENLIGINDEN olculuyor. Alfa 1 ise desen kaybolur, alfa
   dusukse geri gelir. Haleyi temizleyen budur.

Sonrasinda zemin katkisi renkten geri cikarildi
(`C = (gozlenen - (1-alfa)*zemin) / alfa`), aksi halde kenarlar
zeminin grisiyle yikanmis kaliyordu. Bolucu 0.35'te sinirlandi -
sinirsiz bolme cok dusuk alfada rengi beyaza patlatiyordu.

Ic bolgede alfa 1'e zorlaniyor (karakterin kendi dokusu da desen
genligi uretip alfayi dusuruyordu), ama duz renk anahtarinin son sozu
var; yoksa yer catlaklari gibi yari saydam alanlarda dama opak kaliyordu.

**Bilinen artik:** `release_2` karesinde bacak arasindaki yer catlagi
bolgesinde kucuk bir acik leke kaliyor. Oyun olceginde zor fark
ediliyor; rotus yapacaksan oradan basla.

## Hizalama

Gogus kara deligi tum karelerde ortak merkez; 518x686 tuvale oturtulup
%50 kucultuldu: **259x343**. Tuval karakterden uzun cunku `charge_2` ve
`release_2` kareleri ayak altindaki diken alanini da iceriyor.

`boss_void_sovereign.gd`: `_get_target_sprite_height()` = 290
(karakter govdesi bunun ~%65'i, yani ~190 px).
