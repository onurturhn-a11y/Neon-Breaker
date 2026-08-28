# THE VOID ENTITY - kare dosyalari

Kaynak: `Gemini_Generated_Image_ulyvt9ulyvt9ulyv.jfif` (3168x1312),
`COSMIC_VOID_ENTITY_BOSS_SPRITE_SHEET_V1.0`.

| Dosya                | Sheet karsiligi | Poz     |
|----------------------|-----------------|---------|
| `idle_a.png`         | IDLE_A          | idle    |
| `idle_b.png`         | IDLE_B          | idle    |
| `attack_charge.png`  | ATTACK_CHARGE   | charge  |
| `attack_release.png` | ATTACK_RELEASE  | release |
| `hit_a.png`          | HIT_A           | hit     |
| `hit_b.png`          | HIT_B           | hit     |
| `defeat_a.png`       | DEFEAT_A        | defeat  |

`shard_projectile.png` mermi dokusu; THE CORE'un mermisinden renk
tonu kaydirilarak (+85) uretildi.

## Kesim - kristal bosstan neden farkli

THE CELESTIAL'in sert koyu konturu vardi ve kenarlardan flood fill
(tolerans 6) temiz siluet veriyordu. Bu boss ise **uzayla ayni
tonda**: koyu lacivert govde, koyu nebula zemin. Denenenler:

- tolerans 6: flood govdenin icine siziyor, sadece camgobegi kenar
  isigi kaliyor (kapsama %10)
- **tolerans 1**: govde saglam kaliyor (kapsama %49-70) - kullanilan
- rim (camgobegi kenar) tabanli siluet: kenar isigi surekli degil,
  ayrica nebulanin camgobegi bolgeleri de ayni tonda - basarisiz
- flood tohumlu GrabCut: govdeden parcalar yiyor - basarisiz
- parlak-nebula temizligi (celestial'daki koyu-cep kuralinin tersi):
  bu karakterin alev benzeri uzantilari zaten parlak paritidan
  olustugu icin onlari da siliyor - kullanilmadi

Tolerans 1 kadraj kenarlarindaki nebula ceplerini de tutuyordu;
cozum kutulari elle daraltmak oldu. `idle_a` ve `attack_release`
kenarlarinda hala kucuk artiklar var - oyun olceginde (~185 px)
fark edilmiyor, ama rotus yapmak istersen oradan basla.

## Hizalama

Gogus spirali (kara delik) tum karelerde ortak merkez olacak sekilde
666x624 tuvale oturtuldu, sonra %50 kucultuldu: **333x312**.
Ankor icin parlaklik agirlikli merkez kullanildi - spiralin parlak
halkasi kara deligi cevreledigi icin agirlik merkezi tam ortaya
denk geliyor. (Basit "en parlak nokta" yontemi gozleri seciyordu.)

`boss_void.gd`: `_get_target_sprite_height()` = 210.
Zayif nokta ve carpisma kutusu taban sinifta: `CORE_LOCAL = (0,0)`,
`CORE_HIT_RADIUS = 34`, kutu `180x180`.
