# THE VOID ARCHITECT - kare dosyalari

Kaynak: `Gemini_Generated_Image_l8bqavl8bqavl8bq.jfif` (3168x1312),
`ULTIMATE_VOID_ENTITY_BOSS_LEVEL_6_SPRITE_SHEET_V3.0`.

| Dosya             | Sheet karsiligi   | Kullanim               |
|-------------------|-------------------|------------------------|
| `idle_a.png`      | IDLE_A            | idle                   |
| `idle_b.png`      | IDLE_B            | idle                   |
| `charge.png`      | ATTACK_1_CHARGE   | kuyruklu yildiz sarji  |
| `release.png`     | ATTACK_1_RELEASE  | kuyruklu yildiz atisi  |
| `charge_2.png`    | ATTACK_2_CHARGE   | sutun sarji            |
| `release_2.png`   | ATTACK_2_CHARGE(2)| sutun atisi            |
| `hit_a.png`       | HIT_B             | hasar                  |
| `defeat_a.png`    | DEFEAT_B          | yenilgi                |
| `spike_burst.png` | ATTACK_2_RELEASE  | sutunlarin efekt dokusu|
| `spike_shards.png`| PARTICLES_VOID_SPIKES | sutun kiymiklari   |

**Not:** Bu sheet'te `ATTACK_2_RELEASE` kareleri karaktersiz, saf efekt.
Bu yuzden iki `ATTACK_2_CHARGE` varyanti sarj/atis pozu olarak
kullanildi (ikincisinde yer catlaklari daha guclu, atis gibi okunuyor),
efekt kareleri de doku olarak alindi.

Mermi dokusu ayrica uretilmedi; `assets/bosses/void/shard_projectile.png`
ayni temada oldugu icin paylasiliyor.

## Kesim

5. seviye sheet'iyle ayni dama zemini (kare 32 px, tonlar ~190/230,
JPEG oldugu icin gercek alfa yok). Ayni iki asamali anahtar kullanildi:
duz renk anahtari + yerel dama genligi. Ayrintili aciklama icin
`assets/bosses/void_sovereign/FRAMES_README.md`.

Bu sheet'e ozel tek ek: baslik, alt baslik ve etiket bantlari kesimden
ONCE zemin tonuyla boyaniyor. Beyaz yazinin koyu konturu anahtardan
geciyordu ve `idle_b`'nin ust kosesine alt basligin bir parcasi
karisiyordu.

## Hizalama

Gogusteki bronz usturlap tum karelerde ortak merkez; 542x548 tuvale
oturtulup %50 kucultuldu: **271x274**.
`_get_target_sprite_height()` = 230.
