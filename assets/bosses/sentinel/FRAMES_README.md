# THE WARDEN (boss id: `sentinel`) - kare dosyalari

Kaynak: `THE WARDEN.jpg` (2816x1536), tek sheet, 4x3 izgara.
THE SENTINEL'in tek duz PNG'sinin yerine gecer. Boss id kodda
`&"sentinel"` olarak KALIR.

Sheet 10 poz istenmisken **12 poz** ile geldi. Fazla ikisi jeneratör
DURUMU - bossun mekanigi tam olarak o oldugu icin atilmadilar.

| Dosya | Sheet karsiligi | Kullanim |
|---|---|---|
| `idle_a.png` | 1. kare | iki kutuk yaniyor, kepenk kapali |
| `idle_b.png` | 2. kare | vizor parlak, nefes |
| `attack_charge.png` | 3. kare | kutukler doner, kollar gerilir |
| `attack_release.png` | 4. kare | kutukler one bosalir, geri tepme |
| `charge_2.png` | 6. kare | kepenk yariktan sizar, govde kamburlasir |
| `release_2.png` | 7. kare | agir atis kepenkten cikar |
| `exposed_a.png` | 9. kare | **kepenk tamamen acik, cekirdek ortada** |
| `hit_a.png` | 11. kare | zirh catlak, vizor yarik, bir kutuk kirik |
| `defeat_a.png` | 12. kare | yanmis, dumanli, kutukler olu |
| `gen_one_down.png` | 10. kare | **tek jeneratör sonmus** (ara durum) |
| `gen_both_down.png` | 8. kare | **iki jeneratör de sonmus, kepenk hala kapali** |
| `alt_chest_lit.png` | 5. kare | kepenk isikli, kollar asagida (yedek) |

Tasarim fikri: **govdedeki tek sicak isik iki jeneratör.** Butun boss
soguk celik; omuzlardaki iki kutuk turuncu yaniyor. Oyuncu icgudusel
olarak parlayan seye ates eder ve o zaten dogru hamledir. Ikisi kirilinca
kepenk acilip turuncu cekirdek gorunur: "artik buraya vur."
Yani mekanik metinle degil RENKLE ogretiliyor. Eski SENTINEL'de
jeneratörler govdeyle ayni turuncuydu ve dekoratif duruyordu.

`exposed_a`, `gen_one_down` ve `gen_both_down` taban sinifin kare
sozlugunde YOK. Chorus'un `duet`'i gibi `_get_frame_sets()` ezilerek
eklenmeli.

`hit_b` yok - sheet tek hasar karesi verdi. Taban sinif bunu kaldiriyor
(`_hit_sequence` kare sayisini kontrol ediyor).

## Kesim

Zemin ve kesim yontemi diger yeni bosslarla ayni cizgide: duz renk
anahtari, **ic bolgede alfa 1'e zorlama**, zemin katkisinin yalniz sinir
bandinda renkten geri cikarilmasi (`C = (gozlenen - (1-alfa)*zemin) / max(alfa, 0.35)`).
Bu adim atlanirsa dusuk doygunluklu bolgeler zemin cikarma yuzunden renk
kaydiriyor.

Delik doldurma sonrasi hala GERCEK zemin renginde kalan pikseller yeniden
seffaflastiriliyor - yoksa kol/govde arasi bosluklar opak doluyor.

### Bu sheet'e ozel: siyah izgara cizgileri

Zemin saf magenta geldi (temiz), ama hucreleri ayiran cizgiler SIYAH.
Siyah zemin sayilmadigi icin ilk denemede hucreler birbirine baglandi ve
sutun ayirma coktu (12 kare yerine 9 birlesik seride cikti). Cozum:
neredeyse tamami koyu olan satir/sutunlar ayri ayri tespit edilip zemine
yaziliyor.

## Hizalama

Ortak capa: **govdenin ust %60'inin agirlik merkezi** (bas + omuz hizasi).
Gogus merkezi hedeflenmisti; bulunan nokta biraz daha yukarida ama TUM
karelerde ayni yerde - animasyon icin onemli olan tutarlilik.
Tuval **335x259**, kesim sonrasi %50 kucultuldu.
`boss_sentinel.gd`: `_get_target_sprite_height()` = 215.

Jeneratörler govdeye gore sabit ofsette duruyor; mevcut kod
`LEFT_GENERATOR_X = -86.0` / `RIGHT_GENERATOR_X = 86.0` kullaniyor,
yeni sprite'a gore yeniden olculmeli.
