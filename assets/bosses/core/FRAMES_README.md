# THE FURNACE (boss id: `core`) - kare dosyalari

Kaynak: `THE FURNACE.jpg` (2816x1536), tek sheet, 4x2 izgara (8. hucre bos).
THE CORE'un tek duz PNG'sinin (`assets/bosses/the_core.png`) yerine gecer.
Boss id kodda `&"core"` olarak KALIR - derinlik sabitleri, ACHIEVEMENT_BOSS_IDS,
boss_roster_test ve Codex'in basarim sistemi bu id'yi kullaniyor.

| Dosya | Sheet karsiligi | Kullanim |
|---|---|---|
| `idle_a.png` | 1. kare | diyafram kapali, makine karanlik |
| `idle_b.png` | 2. kare | dikisler daha parlak, nefes |
| `attack_charge.png` | 3. kare | diyafram ardina kadar acik, beyaz-sicak merkez |
| `attack_release.png` | 4. kare | kapak carparak kapanirken isik siziyor |
| `hit_a.png` | 5. kare | iki dilim catlak, isik kaciyor |
| `hit_b.png` | 6. kare | diyafram YARI ACIK sikismis, erimis dokuluyor |
| `defeat_a.png` | 7. kare | dilimler dagilmis, oda sonmus |

Tasarim fikri: **telegraf ve govde ayni sey.** Goz aciliyorsa saldiri
geliyor - oyuncunun ayri bir efekt ogrenmesi gerekmiyor. Eski radyal
amblem bunu yapamiyordu cunku her an ayni gorunuyordu.

## Kesim

Zemin ve kesim yontemi diger yeni bosslarla ayni cizgide: duz renk
anahtari, **ic bolgede alfa 1'e zorlama**, zemin katkisinin yalniz sinir
bandinda renkten geri cikarilmasi (`C = (gozlenen - (1-alfa)*zemin) / max(alfa, 0.35)`).
Bu adim atlanirsa dusuk doygunluklu bolgeler zemin cikarma yuzunden renk
kaydiriyor.

Delik doldurma sonrasi hala GERCEK zemin renginde kalan pikseller yeniden
seffaflastiriliyor - yoksa kol/govde arasi bosluklar opak doluyor.

### Bu sheet'e ozel: soluk zemin

Istenen duz magenta gelmedi; zemin soluk mauve (~#E8D0E0), hucre
cizgileri magenta. Ikisi ayri ayri anahtarlandi. Ek olarak duman/isi pusu
icin **soluk piksel testi** var (min kanal > 140 ve max-min < 45).

DIKKAT: delik korumasi bilerek DAR tutuldu (yalniz gercek zemin renkleri).
Soluk testi o korumaya dahil edilirse beyaz-sicak diyafram merkezi de
zemin sayilip govdede delik aciliyor - denendi, oyle oldu.

## Hizalama

Ortak capa: **diyafram merkezi** (govdenin ust %55'inin agirlik merkezi).
Tuval **324x364**, kesim sonrasi %50 kucultuldu.
`boss_core.gd`: `_get_target_sprite_height()` = 190.

**Bilinen artiklar:** `attack_release` karesindeki isi pusu ve `defeat_a`
karesindeki duman prompt'ta ISTENEN seylerdi, artik degiller - ama kesim
sonrasi kenarlari sert kaliyor. Rotus yapilacaksa oradan baslanmali.
