# NEON BREAK CURRENT STATE

Tarih: 31 Ağustos 2026. Proje: C:/Users/barba/Documents/Neon-Breaker  
Branch: integration/neon-break-unified  
HEAD: b0cf8a0 — Queue card choices for multiple level ups.

## Kapsam ve güven düzeyi

Bu rapor HEAD'in temiz hâlini değil, inceleme anındaki **mevcut çalışma ağacını** esas alır. Başlangıçta 19 tracked dosya değiştirilmişti: 12 kaynak dosyası, 6 kart .import dosyası ve export_presets.cfg. Ayrıca 20 yeni kart PNG'si ve yan dosyaları, mobile_card_info.gd ve UID'si untracked durumdaydı. Bunlar bu analizin yaptığı değişiklikler değildir.

- **KOD BULGUSU:** Okunan gerçek fonksiyon/registry davranışı.
- **HESAP:** Bu değerlerden yapılan aritmetik; fiziksel oynanış ölçümü değildir.
- **TASARIM YORUMU / ÖNERİ:** Henüz uygulanmamış değerlendirme.
- Bu tur gerçek Android run'ı, Godot import'u veya oyun çalıştırılmadı. Kaynak/cache/save yazabilecek testler yerine salt okunur inceleme ve bellekte aritmetik kullanıldı.
- Önceki test sonuçları güncel uzun run garantisi sayılmadı. Eski dokümanlardaki 22/23 kart, 8 silah, 21 level-up ve 12,3 dakika değerleri güncel ölçüm olarak kullanılmadı.
- Kaynak yolları aşağıda proje köküne göredir. Fonksiyon isimleri esas referanstır; verilen satırlar çalışma ağacının bu anına aittir.
- Kullanıcının yalnız rapor yazılması talimatı gereği sync, ILETISIM.md güncellemesi, commit ve push yapılmadı.

## Yönetici özeti

**20 aktif kart = 2 CORE + 9 WEAPON + 9 PASSIVE.**  
**9 mounted weapon, 2 slot, 7 progression boss, 5 paddle seçeneği, 9 bina türü/6 Colony platformu.**

Oyun artık yalnız düşen tuğlalardan oluşmuyor. Normal satır akışına normal side-wave, boss side-wave ve mobil doluluk hedefleyen materialize eklenmiş. Güçlü build'lerin ekranı boşaltmasına gerçek bir üretim cevabı var; fakat bu cevabın yoğunluğu ve ödül getirisi oyuncu gücüyle birlikte artıyor.

En önemli ayrımlar:

1. **CORE RESONANCE AKTİF SİSTEM DEĞİL.** Fireball/Pierce ve Chain Lightning aktif. Critical Resonance eski kart adı başka bir pasiftir.
2. Threat artık Core seviyelerini saymıyor: mounted level toplamı + aktif Core varlığı + seçili Core evolution varlığı.
3. Yeni XP maliyeti ilk üç current-level aralığında eski üstel eğriyi koruyor; pahalılaşma Lv4'ten itibaren ekleniyor.
4. Materialize screen-fill gerçekten uygulanmış; mobilde <%45 doluluk tetiklenince %60–75 hedefe kadar devam edebilir.
5. Boss body hasarında altı silah için soyut, cycle başına 1 hasar yolu var. Plasma/Scatter/Homing fiziksel mermi sistemi farklıdır.
6. Zaferde Part Factory bonusunun ölüm settlement'ına girmesi ve HUD'ın yalnız banka PARÇA'sını göstermesi somut entegrasyon sorunlarıdır.

# SYSTEM AUDIT

## 1. Run döngüsü

Kaynak: main.gd, game_manager.gd reset_run(), continuous_brick_field.gd.

1. Menüde kalıcı paddle seçilir; yeni run reseti XP/Lv, slotlar, Core/evolution, lanetler, geçici pickup'lar ve pending seçimleri sıfırlar.
2. Paddle profili uygulanır. Plasma/Fire/Piercing paddle kendi Lv1 weapon/Core'u ile başlar; dolayısıyla her paddle'ın açılışı “boş build” değildir.
3. Top paddle'a bağlı serve durumundadır. Desktop manuel yön, mobil slider'dan ayrı touch/drag aim kullanır.
4. Normal saha 3 satırla açılır. Satır üretimi kırılan tuğla sayısından değil aşağı ilerleme mesafesinden gelir.
5. 8 yeni normal satır Depth artırır. Recovery/materialize bu sayacı artırmaz.
6. Brick kırılması standart hit → destruction → ortak drop/XP/özet zincirine gider.
7. XP eşiklerinin her biri bir pending_card_choices hakkı üretir. Eller sırayla, arada oyun açılmadan tüketilir.
8. Silah kartları mevcut iki slotta Lv1→2→3 ilerler; Core ayrı tutulur.
9. Depth 8/16/24/32/40/48/56 boss checkpoint'leridir. Pending/temizleme/uyarı/arena aşamaları normal üretimi sınırlar; boss sırasında ayrı side-wave vardır.
10. Ball loss, danger line ve düşman saldırıları can kaybı yollarıdır. Önce Colony shield; son can giderse kullanılmamış Revive 2 can verir; aksi hâlde game over.
11. İlk altı progression boss sonrası ödül kararı, ardından normal saha devam eder.
12. Chronoform yenilince zafer ve Ascension unlock. Kodda 57+ formüller bulunsa da normal kazanılmış run otomatik sonsuz moda devam etmez.

Depth, zaman/normal satır üretimiyle ilerler; **boss'a girişte kalan board'un temizlenmesi gibi koşullar yüzünden gerçek ilerleme dolaylı olarak clear hızına da bağlıdır.** XP/run level ise ayrı eksendir.

## 2. Paddle ve Geliştirmeler menüsü

Kaynak: game_manager.gd PADDLE_PROFILES/PADDLE_PRICES; main.gd _open_paddle_shop(); paddle.gd.

| ID / görünen ad | Başlangıç can | Width | Speed | Bedelsiz başlangıç | Profile shield | Ek reroll | Coin fiyatı |
|---|---:|---:|---:|---|---:|---:|---:|
| NEUTRAL / STANDART | 3 | ×1,00 | ×1,00 | Yok | 0 | +1 | 0 |
| PLASMA / PLAZMA | 3 | ×0,92 | ×1,00 | Plasma Lv1 | 0 | 0 | 40 |
| FIRE / ALEV | 2 | ×1,00 | ×0,95 | Fireball Lv1 | 0 | 0 | 50 |
| PIERCING / DELİCİ | 3 | ×0,88 | ×1,10 | Pierce Lv1 | 0 | 0 | 50 |
| NEON_CORE / NEON ÇEKİRDEK | 1 | ×1,15 | ×1,05 | Yok | 2 | 0 | 0 |

NEUTRAL ve NEON_CORE ilk owned listesinde. Diğerleri yeterli coin ile bir kez satın alınır, yeniden seçmek ücretsizdir. Başlangıç reroll = 2 + profile bonusu + Training; banish = 1. Colony shield profile shield'a eklenir. Plasma Lab/Fire Reactor/Piercing Research'in ilgili **temel** affinity bonusu ×2'dir; bütün calibration bonuslarının otomatik ikiye katlandığı anlamına gelmez.

“Geliştirmeler” bu checkout'ta ayrı sınırsız stat satın alma ağacı değil, paddle satın alma/seçim ekranıdır. Bu yüzden burada upgrade Lv1/2/3 fiyat eğrisi yok; her paddle tek unlock. Gerçek seviye meta sistemi Colony'dedir.

Paddle temel hareket hızı 800, base üst sınırı 1100; acceleration ve yatay clamp mevcut paddle kodunda. Profil çarpanları bunun üzerine gelir. Retired paddle_speed/width getter'ları compatibility için duruyor; normal kart havuzundan artık büyütülmez. Geçici Wide, yatay genişliği ×1,25 yapar; kalıcı profile genişliğiyle birleşir.

**Değerlendirme:** Beş profil gerçek trade-off içeriyor. NEON_CORE yalnız kozmetik değildir. Eski “kozmetik alternatif” açıklaması güncel davranışa uymaz. Geniş gövde/iki shield ve tek can deneyimi ayrı test edilmelidir.

## 3. Ball, Core ve Chain

Kaynak: ball.gd, ball.tscn, main.gd trigger_fireball_blast(), chain_lightning_manager.gd.

### Temel top

- Base speed 400; collision progression artışı 8; normal max speed 750. Ball Speed kartı ve sektör hız çarpanı ayrıca uygulanır.
- Ball.tscn collision radius 20. Mobile root scale ×1,3225: fiziksel collision da büyür; bu yalnız görsel değişiklik değildir.
- Desktop aim başlangıcı 15°, yön ayarı 105°/sn, ±60° sınırı. Mobile güvenli yukarı bileşen 0,42: dikeyden yaklaşık ±65,17°.
- Touch/drag hedefi world koordinatına çevrilir; release son geçerli aim'i kullanır. Slider touch'ı ile aim touch'ı ayrı tutulur.
- Paddle bounce max yaklaşık 65°; merkez deadzone ve minimum yukarı bileşen/anti-horizontal korumaları var.
- Normal brick hit 1 HP. Crit, uygun yaşayan/korumasız hedefe ikinci hit üretir; bütün weapon damage'ini ikiye katlayan pasif değildir.
- Boss direkt top hasarı normal/Pierce 2, Fireball 3; sprite boss zayıf noktasında region çarpanı ayrıca ×2 olabilir.
- Ek top sahnesi hâlâ res://ball.tscn instantiate edilir. Normal top, geçici top ve legacy extra-ball helper'ları birbirinden ayrıdır.
- Temporary Extra Ball 12 saniye, tek geçici referans; süre bitince temizlenir. Extra Ball kartı aktif değildir.
- Son topun kaybı can kaybı/yeniden serve yoluna girer; her ekstra top kaybı ayrı zorunlu can kaybı değildir.

### Core

Fireball ve Pierce aynı run'da birbirini dışlar. Seçili Core kendi upgrade'lerini alır. Core cap ilk boss öncesi Lv1, Core yenilince Lv2, Sentinel yenilince Lv3. Weapon cap'i bundan bağımsız Lv3'tür.

| Core | Lv1 | Lv2 | Lv3 | Evolution |
|---|---|---|---|---|
| Fireball | 70×0,80 = 56 radius | 95×0,83 = 78,85 | 125×0,85 = 106,25 | Inferno: radius ×1,45; Napalm: 2,5 sn alan, 0,5 sn tick |
| Pierce | 1 temel penetration | 2 | 3 | Breach +3 penetration; Cascade sequence içindeki temasta Chain tetikleme fırsatı |

Fireball: primary tekrar vurulmaz, radius içindeki diğer uygun bricklere birer hit. Context instance ID ile deduplicate eder. Colony calibration radius ×(1+0,03C) **ana taramadan önce** uygulanır; ana patlama görseli aynı radius kullanır. Reactor ek hedefleri bu radius'un ×1,25 dış bandına kadar arar.

Napalm alanı şu anda 106,25×0,70 = **74,375** radius ile kuruluyor; ana patlama gibi calibration ile büyütülmüyor. Bu ayrı utility alanı olabilir, fakat “bütün ateş alanları büyür” denmemeli.

Pierce toplam kapasitesi = Core level + Research temel bonusu×paddle affinity + floor(calibration/4) + Breach varsa 3. Eski geçici Resonance +1 **yok**. Sequence reset/çarpışma istisnaları mevcut ball mimarisinde korunmuş.

**CORE RESONANCE AKTİF SİSTEM DEĞİL.** Aktif kaynaklarda meter/ready/consume ve ×1,12 Fireball proc bulunmadı. Eski CORE/REZONANS/S1/S2/KALKAN şeridi kaldırılmış. Fireball/Pierce dual-state temas korumaları, debug/legacy güvenliği olarak kalmış olabilir; normal pool'da dual-Core erişilemez.

### Chain Lightning ile karıştırılmamalı

- Chain manager kill penceresi 0,85 sn; Combo Window çarpanı ile uzar.
- Eşikler 3/6/9/12/15/18/21/24/27; hedef sayıları 1/1/2/2/3/3/4/5/6; radius 150.
- Yalnız mounted kill değil, mevcut register_kill yolundan geçen diğer brick kill'leri de zincir durumunu besler.
- Ball teması ready durumda ek hedeflere 1'er hit verir. Cascade temas fırsatlarını artırır.
- Trigger çağrısı charge'ı her kullanımda sıfırlayan bir tüketim sistemi değildir; süre/kombo penceresi önemlidir.
- Fireball/explosion event başına kombo katkısı sınırları korunmuş; buna rağmen seri kill → daha uzun hazır pencere → daha çok clear doğal pozitif döngü yaratır.
- Arc Cannon aynı manager'ın ayrı atış helper'ını kullanır; ball'ın hazır Chain şartını beklemez.

## 4. Dokuz mounted weapon

Kaynak: weapons/weapon_cards.gd, weapons/weapon_system.gd, ilgili controller/projectile dosyaları, weapon_targeting.gd.

Her yeni weapon ilk boş slota Lv1 yerleşir; tekrar kendi slotunda yükselir. İki slot doluysa üçüncü yeni weapon eligible değildir. Lv3 teklif edilmez. State kaynağı GameManager.weapon_slots; plasma_level compatibility aynasıdır. has_weapon_upgrade, **herhangi bir weapon Lv2 olduğunda** true olur; ilk Lv1 acquisition değildir. Run resetinde false.

Tablodaki cooldown'lar controller parametreleridir; telegraph/ateş süresi aynı timer'ın durduğu sistemlerde gerçek start-to-start süreye eklenir. Damage standart brick.hit() üzerinden hit başına 1'dir.

| Card ID / weapon ID / mobil ad | Rarity | Lv1 | Lv2 | Lv3 |
|---|---|---|---|---|
| plasma / PLASMA / Plazma Silahı | Common | 1 namlu; 1,00 sn | 3 paralel namlu; 0,85 sn | 3 namlu; 0,70 sn |
| arc_cannon / ARC_CANNON / Zincir Şimşek | Rare | 1,5 sn; primary+2 jump; r165 | primary+3; r198 | primary+4; r220; terminal r72 |
| scatter_cannon / SCATTER_CANNON / Saçma Topu | Common | 1,2 sn; 3 mermi; -14/0/+14° | 5 mermi; -24/-12/0/+12/+24° | Aynı 5; çarpışan primary 2 shard üretir |
| railgun / RAILGUN / Ray Silahı | Rare | CD3; telegraph0,24; max4 brick; halfwidth8 | CD2,8; max7; halfwidth9,6 | CD2,6; dar koridorda targets sınırsız; halfwidth10,5 |
| homing_missile / HOMING_MISSILE / Avcı Füzeler | Rare | CD2,2; 1 füze; dönüş220°/sn | CD2,1; 2; dönüş264°/sn | 2; dönüş290°/sn; r62 en fazla2 ek hedef |
| pulse_laser / PULSE_LASER / Darbe Işını | Rare | CD4; aktif0,8; tick0,2; halfwidth5 | CD3,7; aktif1,0; halfwidth6 | CD3,5; aktif1,2; halfwidth7; bitişte +1 overload hit |
| mortar / MORTAR / Havan Topu | Common | CD4,5; 1 shell; r78; uçuş0,82 | CD4,1; r97,5; uçuş0,80 | CD3,8; 2 shell, arası0,25; uçuş0,76 |
| drone_bay / DRONE_BAY / Saldırı Dronları | Legendary | 1 drone; 1,35 sn/drone; speed540 | 2; 1,25 sn; speed560 | 2; 0,92 sn; speed590; her3. atış r46 bir ek hedef |
| orbital_marker / ORBITAL_MARKER / Yörünge Saldırısı | Legendary | CD4,8; telegraph0,86; r54; max2 toplam hedef | CD4,2; telegraph0,78; r68; max3 | CD3,9; telegraph0,72; 2 ayrı strike; arası0,18; strike başına max3 |

Diğer gerçek özellikler:

- Plasma projectile speed850. Lab fire-interval azaltır. Lv3 doğal ricochet değildir. Ricochet evolution 3 duvar sekmesi/fan davranışı, Overcharge ayrı ×1,30 fire-rate multiplier.
- Arc yakın uygun hedefler arasında sıçrar; terminal boşalma daha önce vurulmayan radius hedeflerini vurabilir. Terminal hedef sayısını “tam bir” diye sınırlamak yanlış.
- Scatter primary speed820, shard780; shard tekrar bölünmez. Lv3 teorik 5+10 temas kapasitesi, hepsi gerçek hedefe isabet edecek demek değildir.
- Rail telegraph sırasında X kilitler; Pulse paddle'ı takip eder. Rail başlatmalar arası yaklaşık3,24/3,04/2,84; Pulse tam cycle yaklaşık4,8/4,7/4,7 sn. Pulse koridorda duran bir hedefe Lv3 yaklaşık6 tick+1 overload potansiyeli taşır.
- Mortar üst yoğun kümeleri önceler; density radius125/145/145, aday örneklemesi sınırlı. İki patlamanın örtüşmesi ayrı vuruşlar oluşturabilir.
- Drone'lar iki yanda ayrı konum/hedef davranışı taşır; yalnız paddle'a yapışık sprite değildir.
- Orbital primary yok olursa güvenli konum fallback kullanır; işaret ve vurma ayrı aşamalardır.
- Family verisi rapid/chain/area/precision/guided. Family'den otomatik damage bonusu yok.
- Mine Launcher aktif registry/card/runtime bağlantısında yok; geri eklenmiş değil.

### Boss hasarı: önemli asimetri

| Silah | Boss yolu |
|---|---|
| Plasma | Fiziksel projectile; standart plasma hit1; hedef bölgesi önemlidir |
| Scatter | Fiziksel projectile/shard yolu; Plasma tabanıyla boss teması; altı soyut silahın ortak cycle bütçesiyle aynı değildir |
| Homing | Aktif, damage kabul eden boss'a öncelikli homing; boss_pending tek başına hedefi elemez; 2 füze iki fiziksel hit fırsatı taşır |
| Arc/Rail/Pulse/Mortar/Drone/Orbital | Ortak apply_boss_cycle_hit; ilgili cycle başına1 body hit; brick sayısına/tick sayısına bağlı artmaz |

Drone boss bütçesi drone başına değil controller interval'ına bağlı. Mortar/Orbital iki atışını boss'a çift bütçe yapmaz. Pulse her tick boss vurmaz. Generic hit helper hedef mesafesi/gerçek projectile temasını beklemeden boss'a ulaşabilir; Orbital'da telegraph görselinden önce bu soyut hasar mümkündür.

**Sentinel istisnası:** Generic mounted hit core bölgesine gönderilir. Shield kapalı değilse generator'ı kırmaz; body hasarı emilir. “Dokuz silah boss uyumlu” demek “dokuzu generator aşamasında eşit yararlı” demek değildir. Altı silahın açık core penceresinde katkısı var; generator açmak hâlâ top/fiziksel isabet için kritik.

## 5. Aktif kart havuzu ve pasifler

Core/weapon tabloları 11 kartı kapsar. Aşağıdaki 9 pasifle toplam **20** olur.

| ID | Mobil görünen ad / registry adı | Rarity | Lv1 / Lv2 / Lv3 | Normal max |
|---|---|---|---|---:|
| xp_gain | XP Takviyesi / VERİ EMİLİMİ | Common | XP +%20 /40 /60 | 3 |
| drop_rate | Ganimet Avcısı / TARAMA DİZİSİ | Common | chance ×1,25 /1,50 /1,75 | 3 |
| magnet_duration | Güçlü Mıknatıs / ÇEKİM ALANI | Common | duration ×1,30 /1,60 /1,90 | 3 |
| combo_window | Kombo Ustası / ZİNCİR BELLEĞİ | Common | window ×1,25 /1,50 /1,75 | 3 |
| crit_hit | Kritik Vuruş / KRİTİK REZONANS | Rare | ball crit %14 /28 | 2 |
| salvage_find | Hurda Avcısı / HURDA DEDEKTÖRÜ | Rare | Part chance ×2 /3 | 2 |
| ball_speed | Hızlı Top / AŞIRI İVME | Rare | ball speed +%10 /20 | 2 |
| revive | İkinci Şans / YEDEK ÇEKİRDEK | Epic | run başına bir kez ölümde2can | 1 |
| slow_descent | Yavaş İniş / ZAMAN AĞI | Epic | descent speed ×0,85 | 1 |

Ascension5/10, crit_hit ve ball_speed için normal2 tavanını +1/+2 genişletebilir: en yüksek crit%56, ball speed+%40. “Bütün kartlar Lv3” doğru değil. Salvage Find aynı genişleyen grupta değil.

Rarity adetleri: **Core2, Common7, Rare7, Epic2, Legendary2.** Common weapon3, Rare weapon4, Legendary weapon2.

Normal havuzdan çıkma: banish, max level, karşı Core lock, Core milestone cap, yeni weapon için dolu slot. Aynı elde tekrar yok. Reroll ve queue elleri aynı eligibility yolunu kullanır.

Rarity per-card ağırlığı:
- Core: mounted count + active Core count <2 ise48, değilse24.
- Common34.
- Rare=min(15+0,65D;34).
- Epic=min(4+0,30D;14).
- Legendary=min(1,5+0,10(D−1);4).
- Yalnız owned Legendary Lv2/3 upgrade adayı ×4. İlk acquisition bonus almaz.

Bunlar kategori yüzdesi değildir; eligible kart adedi ağırlık toplamını değiştirir. Örneğin A0, D1, boş build/banish yokken ilk çekilişte toplam ağırlık yaklaşık455,15; Core%21,1, Common%52,3, Rare%24,1, Epic%1,9, Legendary%0,66. Bu **elin tamamında görülme** değil ilk tek çekiş olasılığıdır. İlk kart sabit değildir.

### INACTIVE / LEGACY

paddle_width, paddle_speed, extra_ball registry metadata/getter/apply helper olarak bulunabilir; CardPool.get_ids()/has_card filtreleri bunları teklif dışına çıkarır. Temporary Wide ve temporary Extra Ball bununla kaldırılmamıştır. Yeni20 kart artwork listesi bunları kapsamaz.

Mobilde adlar DISPLAY_NAMES ile Türkçeleşir, registry başka ad/İngilizce title tutabilir. Epic “EFSANE”, Legendary “LEGENDARY” etiketi terminoloji tutarsızlığıdır. PNG içindeki stat değil CardPool açıklaması bilgi panelinin kaynağıdır; açıklamanın kendisi hâlâ elle yazılmış metindir, controller parametrelerinden otomatik türetilmez.


## 6. XP / run level

Kaynak: game_manager.gd:957 get_run_xp_requirement(), :975 normalize_collected_xp(), main.gd:3348 add_xp().

**Current level L'den L+1'e maliyet: round(100 × 1,20^(L−1) × M(L)).**

| L aralığı | M |
|---|---:|
| 1–3 | 1,00 |
| 4–5 | 1,15 |
| 6–7 | 1,30 |
| 8–9 | 1,50 |
| 10–12 | 1,75 |
| 13–15 | 2,00 |
| 16+ | 2,25 |

| Run level | Sonraki level XP | Bu level'a toplam XP |
|---:|---:|---:|
| 1 | 100 | 0 |
| 3 | 144 | 220 |
| 5 | 238 | 563 |
| 8 | 537 | 1.512 |
| 10 | 903 | 2.694 |
| 12 | 1.300 | 4.681 |
| 15 | 2.568 | 9.904 |
| 20 | 7.188 | 31.081 |
| 25 | 17.887 | 84.573 |
| 30 | 44.508 | 217.679 |

Orb base value10. Normal orb pickup XP işlemi:
1. Depth gain = 1+0,06×(D−1).
2. Build gain = (1+0,20×XP Gain level+Data Archive bonus) × curse gain × (1+0,15×Ascension).
3. Base orb×gain×Depth önce integer round/min1.
4. Normal satır metadata'sındaki row scale uygulanır; kesir kalanı run içinde taşınır.
5. Eşikler while ile işlenir; her level-up +1 pending_card_choices.

Row scale = round(13×min(platform/adaptive öncesi Depth fill+sector fill;0,95)) / actual row brick count. Spawn anında dondurulur. D56 sonrasındaki satırlar1; side-wave/materialize1. Eşit destroy/collect oranında normal satırın beklenen XP bütçesi viewport'tan bağımsızlaşır; **recovery sayısı ve elite/drop dağılımı eşitlenmez.**

Birden çok eşik aşılırsa hak kaybolmaz. Reroll/banish hak tüketmez. Card commit tekrar giriş korumalı. Boss reward/evolution ortak çözüm sırasıyla yarışmaz; reset/ölüm pending'i temizler, revive yaşamaya devam ettiği için aynı haklar korunur. Uygun kart kalmazsa mevcut fallback ödül yolu vardır.

**Yorum:** Lv3'e ulaşmak hâlâ toplam220 XP; başlangıçtaki ilk güçlü sıçramayı maliyet artışı sınırlamaz. Lv8 ve sonrası hissedilir yavaşlar. Eski21-card/run ölçümü, bu curve ve materialize değişikliği sonrası geçerli kabul edilemez.

## 7. Threat: gerçek formül ve etkiler

Kaynak: game_manager.gd:1039–1124, level_generator.gd _apply_build_toughness().

T = mounted level toplamı + int(Fireball aktif) + int(Pierce aktif) + int(aktif Core evolution var).

Normal mutual exclusion run'ında max8: ikiLv3 + Core var1 + evolution1. Core Lv1→Lv3 tek başına Threat artırmaz. Plasma evolution, passive/Colony güçleri, Legendary etiketi ayrıca sayılmaz. get_power_synergy_tier() ayrı state değil aynı Threat helper'ının alias'ıdır.

| T | Tier | Tough batch hedefi | Recovery interval çarpanı | Mobile fill hedefi |
|---:|---:|---:|---:|---:|
| 0 | 0 | %0 ek hedef | 1 | %60 |
| 1 | 0 | %0 ek hedef | 1 | %60 |
| 2 | 1 | %17,5 | 1 | %64 |
| 3 | 1 | %27,5 | 0,8696 | %68 |
| 4 | 2 | %35 | 0,8333 | %70 |
| 5 | 2 | %45 | 0,80 | %72 |
| 6–8 | 3 | %50 | 0,80 | %75 |

- Global descent interval tier1/2/3 ×0,94/0,90/0,86.
- Mobile ayrıca tier1/2/3 ×0,92/0,85/0,78 interval ve +0,05/0,10/0,15 fill kullanır; Depth≥4, danger mesafesine göre yumuşatılır.
- Danger'a220px yakında baskı azalır;120px çevresinde adaptive hız desteği durur.
- Tier2/3 Shield chance'a Depth≥6 +0,02/+0,03; final cap0,07.
- Side Attacker tier3 interval×0,85.
- Toughness normal satır/normal side-wave ve güncel mobil materialize batch'inde uygulanır. Boss wave dışlanır.
- Hedef sayısı stochastic round, batch'in yarısını aşmayacak target, en az bir uygun1HP normal bırakma kuralı. Zaten tough/elite olanlar hedefe sayılır.
- Bu **bütün sahaya kesin%50HP2 cap** değildir. Önceden üretilen composition/elite'ler demote edilmez; special row cap de sonradan yapılan normal→2HP promotion ile aynı mekanizma değildir.

**Denge yorumu:** T aynıyken Plasma Lv3 ile Arc Lv3 veya yüksek calibration Fireball aynı çıktı üretmez. Threat yaklaşık build kapasitesi ölçer, clear-rate ölçmez. Doluluk feedback'i bunu kısmen tamamlar ama oyuncunun gerçek öldürme performansı ayrıca ölçülmüyor.

## 8. Brick türleri ve HP

Kaynak: brick_piece.gd, shield_brick.gd, elite_bricks.gd, level_generator.gd.

| Tür | HP | Koşul / mekanik | Reward |
|---|---:|---|---|
| Normal | 1 | Standart kaynak | Ortak drop |
| Armored/tough | 2 | Depth roll veya Threat batch promotion | Aynı ortak drop; HP başına ek XP yok |
| Explosive | 1 | Depth+sector chance; ölünce135 radius, zincir gecikmesi0,075sn | Ortak drop; tek context tekrar isabeti önler |
| Shield source | 1 | Depth6+ eligibility; satır komşularını korur | Ortak drop |
| Shield alan brick | Kendi HP'si | Source yaşarken hit bloklanır; bağımsız yeni HP türü değil | Kendi drop'u |
| Elite | 3 /4 /5 | D4–11 /12–19 /20+; amber çerçeve | Drop multiplier3 |
| Side Attacker | Brick HP sistemi yok | Gir→hedefle→bir projectile→çık; game_brick normal destroy hedefi değil | Normal brick loot hedefi değil |
| Materialized | 1; seçili batch promotion2 | Ayrı yeni hasar sınıfı değil; canonical brick_piece | Side-wave drop profili |

Healer/Commander aktif türler değil. Moving brick eski scene/script olarak disk üzerinde bulunuyor; güncel normal field bunu instantiate etmiyor.

Elite chance: D<4 sıfır; diğer durumda min(min(0,01+(D−4)×0,0022;0,045)+0,004A;0,065). Satır başına max1. Roll her brick'e koşulsuz değil, uygun normal adaylara. HP5 üstüne Depth yüzünden çıkmaz.

### Depth composition tabanı

Aşağıdaki Armor/Shield sütunları configure_for_depth tabanıdır; effective helper düzeltmeleri ayrıca uygulanır.

| D | Fill | Armor | Explosive | Shield |
|---:|---:|---:|---:|---:|
| 1 | .45 | 0 | .03 | 0 |
| 2 | .60 | 0 | .04 | 0 |
| 3 | .72 | 0 | .05 | 0 |
| 4 | .80 | .03 | .05 | 0 |
| 5 | .85 | .05 | .06 | 0 |
| 6 | .88 | .08 | .07 | .015 |
| 7 | .90 | .12 | .08 | .025 |
| 8 | .92 | .17 | .09 | .035 |
| 9 | .93 | .22 | .10 | .045 |
| 10 | .94 | .25 | .11 | .050 |
| 11 | .945 | .27 | .115 | .055 |
| 12 | .95 | .30 | .12 | .060 |
| 13+ | .95 | .30 | .12 | min(.055+(D−10)×.005;.07) |

Armor effective: aktif Core/weapon yoksa0; D5/9/13/17/21 eşiklerinde sırasıyla+.02/.04/.06/.08/.10; önce.30 cap, curse+.10 sonrası.42 cap.
Shield: benzer eligibility; D9/13/17/21+.02/.03/.04/.05 ve Threat bonusu; final.07.
Explosive D21 sonrası depth başına+.00075, late bonus max.03; ana.15 cap, sector eklenince final.32 cap.
Special row cap max(1,floor(row_count×.40)); roll sırası/kalan bütçe yüzünden tablo değerlerini toplayıp final gerçekleşen yüzdeler denemez. Elite ayrı aday/bütçe, Threat promotion ayrı son işlem.

## 9. Normal üretim, mobile grid ve iniş

Başlangıç3 satır; rows_per_depth8; step10worldpx; tween0,21sn. distance_since_row gap_y'ye ulaşınca normal row doğar, kalan mesafe korunur.

- Desktop scale(.6765,.6435), gap74×29; sütun=floor((visible_width−67,65)/74)+1; minimum row5. 13 sabit actual sütun değil, XP referansıdır.
- Portrait mobile brick scale bu değerlerin×1,3924'ü: fiziksel genişlik yaklaşık94,20, yükseklik31,36. Gap≈100,20×36,36. Saha6 sütuna yetmezse5; minimum row2.
- Fill gerçek adet=clamp(round(columns×effectiveFill),minimum,columns). Random pattern adet değil yerleşim değiştirir.
- Mobile D4+ fill+.10; adaptive/sector dahil final≤.95. 6×.95 yuvarlaması **6/6 dolu satır** üretir: parametre%95 olsa bile hücre doluluğu%100 olabilir.
- D1 altı mobile sütun: round6×.45=3; başlangıç yaklaşık9 brick. Desktop13 referans sütunda6×3=18. Actual desktop viewport daha genişse daha fazladır.
- Danger=anlık paddle collision top−80worldpx. Brick alt sınırı geçince kaldırılır, mevcut danger cooldown0,85sn can kaybını kümeler.

Taban interval D1 desktop2,05; mobile1,50. D2..6:1,35/1,20/1,05/.95/.82; D7+ .75.
Ham interval = taban × postboss × build × lateDepth × sector × curse × Ascension × mobile(.82).
Normal A0 floor.45. Mobile adaptive ikinci çarpan/floor sonrası Slow Descent varsa **/.85**.
Ascension A floor=.45×.98^A; A10≈.368sn. “Hiçbir durumda .45 altına inmez” güncel birleşik kod için yanlış.

LateDepth multiplier:
D1–4=1;5–9=.94;10=.91;11=.89;12=.87;13–16=.77;17–20=.69;21–24=.62;25–32=.56;33–40=.51;41–48=.47;49–56=.43;57–64=.40;65–72=.37;73+=.34.
İlk boss sonrası ek postboss: desktop.88/mobile.84.

Arz hesabı: ortalama row/sn≈10/(gap_y×interval); brick/sn bunun row adediyle çarpımıdır. A0 floor'da desktop13sütun/12brick satır yaklaşık9,20brick/sn; mobile6sütun/6brick satır yaklaşık3,67brick/sn. Bu **normal row arzı**, recovery ve boss süreleri hariçtir; gerçek kill hızı değildir.

Depth'in etkileri: taban/late interval, fill, special/elite, side attacker, boss milestone, rarity, XP gain ve normalizasyon D56 sınırı. Threat bunlardan ayrı run-build sinyalidir.

## 10. Side-wave ve materialize

### Normal side-wave

Kaynak: continuous_brick_field.gd _update_side_wave(), _try_spawn_side_wave(), _find_upgraded_side_wave_targets().

Desktop eski occupancy paydası columns×8. Tetik<.25; ayrıca merkez bölge≤1 brick ise önceki normal yan dalga bitmiş ve1,25sn safety geçmişse merkez refill yolu var. İlk safety3,5sn, attempt .5sn, normal cooldown7sn. Boss/menu/card/evolution/sector/danger yakınlığı bloke eder.

- Normalde4 brick/1 sıra.
- has_weapon_upgrade=true olduğunda4+4 iki sıra; uygun alan yoksa3+3 sonra2+2; güvenli yer yoksa spawn yok.
- İlk weapon Lv1 değil **Lv2 upgrade** bunu açar.
- Rastgele sağ/sol;0,5–0,8sn giriş tween'i.
- Danger'dan120px güvenli mesafe; aynı anda entry ve materialize başlatılmaz.
- Normal side-wave tag'i drop chance×.35. Yeni normal Depth satırı sayılmaz.
- Mobile recovery ayrı karar katmanı aynı oluşturma helper'ını kullanır; living recovery cap12 ve shared spacing vardır. Cap12 bütün normal saha veya materialize toplam cap'i değildir.

### Boss side-wave

8–12sn aralık,2–4brick; normal iki-sıra upgrade kullanılmaz. Boss projectile ile1sn olay ayrımı. Normal üst-row üretimi dururken boss side-wave brick'leri mevcut step akışında inebilir; “boss'ta bütün brick hareketi durur” yanlış.

**Ödül farkı:** _try_spawn_side_wave yalnız not boss_wave dalında is_side_wave_brick metadata ekliyor. Dolayısıyla boss side-wave güncel kodda normal side-wave'in .35 indirimiyle aynı değildir; etiketsiz brick default drop profilini kullanır. Elite override ayrıca değerlendirilir.

### Materialize screen-fill: UYGULANMIŞ

Kaynak: continuous_brick_field.gd:107–160 safe grid; _update_mobile_pressure(), _begin_materialize(), :478 _finish_materialize().

Mobile:
- Fresh trigger occupancy<.45.
- Hedef T0/1 .60; T2 .64; T3 .68; T4 .70; T5 .72; T6+ .75.
- missing=max(0,round(capacity×target)−active).
- Event başına max24; hedefe birden çok event gerekebilir.
- Fill latch aktive olunca .45 tekrar geçilse de hedef tamamlanana kadar sürer. Bu önemli histerezistir.
- Safe grid playable üstünden danger−120 sınırına kadar mevcut gap ile oluşturulur. Capacity=free safe cell+active brick. Sabit6×8 değildir.
- Ball çevresinde24px ek koruma, brick overlap denetimi, sınır kontrolü. Hareketli brick iki potansiyel hücreyi bloke edebilir; kapasite zamanla değişir.
- 2–4 yatay komşu küçük cluster, satırlar karışık seçilir; tek kalın yatay duvar garantilenmez.
- .70sn marker; henüz collision yok. Bitişte yeniden güvenlik/missing kontrolü, canonical brick instantiate ve collision.
- Mobile marker alpha .16→.40; yumuşak scale; desktop farklı görsel yoğunluk.
- Oluşanlar1HP, sonra mobile Threat promotion uygulanabilir. Yeni ayrı materialize HP/damage sistemi yok.
- Side-wave tag'i nedeniyle drop chance×.35; row scale1. Depth ve normal row timer değişmez.
- Boss/pending/drain/temizleme sırasında marker/tween iptal edilir.
- Desktop .25 eski occupancy,4sn cooldown ve eski8/12 hedefli daha dar merkezi materialize yolu kullanır; mobile target-fill'i aynen kullanmaz.

### Adaptive katman

| Occupancy | State | Recovery timer | Materialize timer |
|---|---|---:|---:|
| ≥.45 | Normal | ×1 | ×1 |
| .30–.45 | Low | ×.75 | ×.80 |
| .25–.30 | High | ×.50 | ×.60 |
| <.25 | Emergency | ×.35 | ×.50 |

Materialize base4sn; adaptive ve Threat recovery multiplier birleşir; en kısa1,6sn. Shared minimum olay aralığı1,25sn; .5sn karar örneklemesi/marker süresi fiili sıklığı ayrıca etkiler. Materialize önceliklidir; aynı anda normal recovery akışıyla çifte spawn yapılmaz.

**Kritik:** Eski occupancy denominator columns×8, yeni safe grid ise danger'a kadar birçok satırdır. Aynı “%60” ikisinde aynı brick sayısı değildir. Örnek varsayımsal capacity150'de hedef90–113brick, eski6×8 capacity48'de29–36 eder. Bu bir fiziksel Android ölçümü değil, iki paydanın farkını gösteren aritmetiktir.

## 11. Side Attacker, sektör, lanet ve Ascension

side_attacker_spawner.gd / side_attacker.gd:
ilk5–7sn; sonra D1–2 10–14, D3–5 8–12, D6+6–10. Active actor varken yenisi bekler.
Çarpanlar mobile.89, Tier3.85, lateDepth (D9 .90;13 .80;17 .70;21 .60'tan yavaş azalış;29 .55;41 .50;57 .44), sector, hunted curse.
Actor entry.32, hold.55, telegraph.30, exit delay.30 ve exit.32; tek projectile speed365. Bu aralıklar saf“ateş/saniye” değildir, actor süresi de var. Boss pending/starting normal actor ve projectiles'ı temizler.

Sektörler **4 Depth'te bir**; boss başına bir sektör değil:
1 Sessiz Kuşak D1–4 nötr.
2 Enkaz Tarlası D5–8 explosive+.06.
3 Düşük Yerçekimi D9–12 interval×1.12, ball×1.15.
4 Sıkışma D13–16 interval×1.06,fill+.05.
5 Avcı Kuşağı D17–20 interval×1.10,attacker interval×.55.
6 Çöküş Hattı D21–24 fill+.05,explosive+.02,ball×1.05,attacker×.78.
7 Boşluğun Dibi D25+ fill+.08,explosive+.04,ball×1.08,attacker×.66.

Lanetler: haste interval×.88; armor chance+.10; hunted attacker interval×.65; frail anlık−1life. İlk üçü gain+.25, frail+.40; farklı lanetlerin gain'i toplanır, Ascension gain ile çarpılır. Frail son canı götürecekse sunulmaz; aynı lanet tekrar alınmaz.
“%12 hızlı” ile interval×.88 matematiksel olarak speed+%13,6; “%35 daha sık” ile interval×.65 +%53,8 cadence'tır. UI bu ayrımı yuvarlak ifade ediyor.

Ascension0–10: interval×.96^A, floor×.98^A, bossHP×(1+.12A), gain×(1+.15A), elite chance+.004A cap.065; ilgili pasif cap'leri5/10'da yükselir. Seçili Ascension run başında dondurulur, zafer bir sonrakini açar.


## 12. Drop, ekonomi ve Colony

Kaynak: main.gd:2850 _resolve_brick_collectible_drop(), :2920–2990 spawn/collect; game_manager.gd:1248 carry/bank/settle.

Tek random roll sırası: **Part → Coin → EXP → Heart → Magnet → Wide → Extra Ball**. Bir brick en fazla bir pickup üretir.

| Pickup | Base chance | Etki / koşul | Dünya cap'i |
|---|---:|---|---|
| Building Part | .08 | 1 temel PARÇA; Salvage×(1+level), Drop Rate; kazanç sonra curse/Ascension | **1** |
| Coin | .006 | 1 temel coin; Refinery/calibration ve Drop Rate sonrası final chance≤.01 | **1** |
| EXP | .20 | 10base XP; ilk kart öncesi chance×1,5; normalization/gain yukarıda | Bu ikisi gibi1cap yok |
| Heart | .06 | +1can, max5; tam canda Tech salvage varsa dönüştürme |1cap yok |
| Magnet | .03 | Base 10 sn; süre Colony×kart×calibration | Aktif magnet varken yeniden activation drop'u engellenir |
| Wide | .015 |12sn ×1,25paddle width | Aktif effect varken teklif edilmez |
| Extra Ball | .015 |12sn bir geçici top | Aktif effect varken teklif edilmez |

Part/Coin aktif referans ataması add_child öncesinde yapılır; aynı frame ikinci spawn guard'ı vardır. Collected/freed/queued referanslar canlı cap sayılmaz. Cap doluyken chance sıfırlanır, sonraki roll aralıkları tekrar şekillenir. Dolayısıyla “Part cap yalnız görsel yoğunluğu etkiler” doğru değil: diğer loot'a kalan random alan da değişir.

Normal/side/materialize:
- Normal drop multiplier1, normal-row XP normalization metadata.
- Normal side-wave/materialize chance×.35, XP scale1.
- Elite multiplier3 override; bu .35 ile mutlaka çarpılmaz.
- create_side_wave_group allow_shield=true gönderdiğinden “side-wave elite içermez” yorumuna rağmen uygun yan dalga brick'i elite olabilir. Bu source yorumuyla runtime dalı arasındaki çelişkidir.

Base normal toplam chance .406; kalan boş. Drop Rate3+Salvage2'de Part=.42, Coin≤.01, EXP=.35, Heart=.105, Magnet=.0525, Wide/Extra=.02625'er: toplam.99. İlk-card bonusu veya Elite çarpanı ile toplam1'i aşabilir; sıralamanın sonundaki pickup'lar fiilen azalır. Bu normalleştirilmiş ağırlıklı kategori seçimi değildir. Max Part/Coin cap bu hesabı her an değiştirir.

Coin hemen total_coins'e kaydolur; Part önce **carried_salvage**, sonra banka total_salvage. Ölümde taşınanın floor(yarısı) kurtulur, kalanı kaybolur. Bank seçeneği taşınanın tamamını güvenceye alır. Zafer mevcut taşınanı tam bankalar. Başlangıç yeni meta100 PARÇA; bu placeholder ekonomi avantajıdır, boş ekonomik başlangıç değildir.

Coin fiyatları40/50/50; unlock toplam140coin. Boss Loot coinlerinin ilk6 toplamı92; buna pickup kazancı eklenir. “Tek run'da kesin hepsi açılır” denemez; her boss'ta Loot seçimi varsayımı bile yalnız92garantili coin.

**Somut bug — zafer factory bonusu:** main.gd _trigger_run_victory() önce bankalar; _show_victory_screen() sonra _award_colony_run_end_bonus_once() çağırır. Bu helper Factory bonusunu carried'a ekleyip koşulsuz settle_carried_salvage_on_death() çalıştırır. A0/lanetsiz Lv3Factory7 bonusun yalnız3'ü kalıcı olur,4'ü “kaybedilir”; zaferde de. Önceden taşınan toplam tekrar yarılanmıyor, yalnız sonradan eklenen bonus etkileniyor. Bu tur düzeltilmedi.

### Dokuz bina

Her bina maxLv3, unique type, altı platforma sığmalı; para ve boş platform dışında zorunlu Depth unlock yok. Calibration Lv3 sonrası sınırsız; maliyet round(40×1,35^C).

| ID / bina | Build / Lv2 / Lv3 PARÇA | Lv1 / Lv2 / Lv3 temel etkisi | Calibration C |
|---|---|---|---|
| plasma_lab / Plazma Laboratuvarı |10/20/35|interval azaltımı %11,5/%13/%15; matching paddle ×2|interval ×.98^C|
| fire_reactor / Ateş Reaktörü |20/24/40|ek hedef1/1/2; affinity×2|ana splash radius×(1+.03C)|
| piercing_research / Delici Araştırma |20/24/40|+1/+2/+3penetration; affinity×2|+floor(C/4)|
| part_factory / Parça Üretim Tesisi |55/30/50|run sonu2/4/7 temel Part|+floor(C/2)|
| coin_refinery / Coin Rafinerisi |35/35/60|chance+.001/+.0022/+.0035|+.0003C; finalcap.01|
| tech_center / Teknoloji Merkezi |25/40/65|magnet duration×1.15/1.30/1.50; full-heartPart0/1/2|duration×(1+.05C)|
| shield_generator / Kalkan Jeneratörü |22/44/70|run başı1/1/2shield|+floor(C/3)|
| sim_chamber / Eğitim Simülatörü |20/40/68|run başı1/2/3reroll|+floor(C/2)|
| data_archive / Veri Arşivi |16/32/55|XP+%8/%16/%25|+%2C, XPkartıyla additive|

Plasma final normal interval = levelInterval×max(1−LabReduction×affinity;.55)×.98^C; Overcharge varsa ayrıca/1,30. Research toplamı Core/Breach ile additive. Fire calibration alanı büyüttüğü için hedef kapasitesi yoğun sahada kabaca radius karesiyle büyüyebilir.

### Lv3 calibration örnekleri

| Bina | C5 | C10 | C20 |
|---|---|---|---|
| Plasma, affinity yok, interval çarpanı |.768|.695|.567|
| Fire, radius / yaklaşık alan |×1.15 /1.32|×1.30 /1.69|×1.60 /2.56|
| Pierce, affinity yok Research katkısı |+4|+5|+8|
| Factory, settlement öncesi base ödül |9|12|17|
| Refinery, Drop Rate yok final |%1 cap|%1 cap|%1 cap|
| Tech, kart yok magnet duration çarpanı |1.875|2.25|3.00|
| Shield run charges |3|5|8|
| Training ek reroll |5|8|13|
| Data toplam XP bonusu |%35|%45|%65|

Coin Refinery Lv3 zaten.0095; C2'de kart olmadan.01 cap'e dayanır. Bundan sonra calibration fiyatı yükselirken coin chance artışı yutulabilir. Shield Lv1=Lv2 temel1charge, Fire Lv1=Lv2 temel1ekhedef: bu seviye adımları temel etkide flat kalır. Bilinçli unlock/calibration basamağı olabilir ama UI'da değer sıçraması gibi anlatılmamalı.

Hissedilebilirlik: Fire/Pierce/Shield çok hissedilir; Plasma/Training/Data hissedilir; Tech pickup frekansına bağlı; Factory settlement yüzünden zayıf hissedilir; Refinery cap'e ulaşınca ek upgrade/calibration neredeyse görünmez. Uzun vadede Shield/Training lineer sınırsız; Plasma interval üstel küçülür; Meta güç artışı Threat'e yansımaz.

Altı binanın live scene'i var. Shield/Training/Data fallback/procedural görselle çalışır. Görsel placeholder, save veya bonusun inactive olduğu anlamına gelmez.

## 13. Boss tablosu, ödül ve süre

Kaynak: main.gd boss constants/reward/transition, boss_core.gd, boss_sentinel.gd, boss_sprite_entity.gd ve türevleri.

HP tabanı A0; A için round(baseHP×(1+.12A)).

| D / boss | HP | Phase HP oranı | İmza ve bekleme/telegraph |
|---|---:|---|---|
|8 Core|100|>%75 /%25–75 /≤%25|1,8–2,4sn bekleme +.35telegraph; tanımlı1/2/3açı, aktifprojectile cap2|
|16 Sentinel|145 +2×14generator|>%60 /%30–60 /≤%30|2–2,4sn; P3interval×.85; P2her4.,P3her3. atış heavy; .6telegraph|
|24 Celestial|200|>%65 /%32–65 /≤%32|1/2/3 sütun; CD5–5,6 /4–4,6 /3,1–3,6; telegraph1,1/.95/.8|
|32 Void Entity|260|aynı65/32|tekillik1/2/2; CD6,4–7 /5,4–6 /4,4–5; tel1,15/1/.85; r135,3sn(P3+0,8)|
|40 Void Sovereign|330|aynı65/32|tarayan torrent+diken; P3ardışık; CD6,2–6,8 /5,2–5,8 /4,2–4,8; tel1,1/.95/.8|
|48 Void Architect|410|aynı65/32|comet + iki dalgalıpillar; CD5,9–6,5 /4,9–5,5 /3,9–4,5; tel1,08/.92/.78|
|56 Chronoform|500|aynı65/32|rune sweep + tek boşlukluwall; CD5,7–6,3 /4,7–5,3 /3,7–4,3; tel1,05/.9/.75|

Core speed110 ve kısa .25–.70sn hareket durakları; Sentinel65/82/92; diğerlerinin ortak hareket58/74/88. Ortak normal projectile350, normal fire2,4–2,9, P3daha sık; imza saldırısı esnasında normal atış için blok vardır.

**Core cap:** P3 [-12,0,+12] tanımlı ama loop'ta cap2 sebebiyle hepsi aynı anda doğamaz. Board'da başka sahipli mermi yoksa ilk iki oluşturulur, üçüncü engellenir. Böylece P3 gerçek pattern tanımlı3'e eşit değildir ve açı sırası simetriyi etkileyebilir. Bu sonradan istenen güvenlik cap'inin sonucudur; eski “P3 kesin3mermi” raporu geçersizdir.

Sentinel iki generator bitince core10sn açık, enraged8sn; regen.8sn(P3×.72). Generator HP değişmez. Full-body soyut weapon hit generator'ı kırmadığı için oyuncunun top isabet kalitesi önemlidir.

Celestial beam halfwidth27, lifetime.5; Sovereign torrenthalf46/1,45sn ve spikehalf62; Architect pillarhalf58; Chrono wallgap yarı78, sweep1,15sn boyunca.16sn volley. Bunlar eşzamanlı bütün saldırıların toplam kaçış alanı değil tek mekanik sabitleridir.

Düşman projectile can hasarı main'de 0,70 sn kilit kullanır; danger line ayrı 0,85 sn cooldown taşır. Boss hazardlar/mermiler ayrıca consumable veya olay bazlı korunur; main lose_life() tüm hasar tiplerini kapsayan tek global invulnerability timer içermez. Dolayısıyla “aynı anda iki farklı tehlike asla iki can götürmez” garantisi verilemez. Gerçek yoğun saldırı testi gerekir.

### Ödül

| Boss | Loot PARÇA/Coin | Eksik candayken Repair | Tam canda Repair |
|---|---|---|---|
|Core|16/8|+2can +8Part|8Part|
|Sentinel|20/10|+2can +10Part|10Part|
|Celestial|24/14|+2can +12Part|12Part|
|Void|28/16|+2can +14Part|14Part|
|Sovereign|32/20|+2can +16Part|16Part|
|Architect|36/24|+2can +18Part|18Part|
|Chronoform|44/30 tabloda var|+2can+22 tabloda|22 tabloda|

**Chronoform normal run'da reward screen yerine victory'ye gider; son satır tanımlı ama normal seçimde verilmez.** Tactical her aşamada+2reroll+1banish. Carried>0 ise Bank; ayrıca uygun Curse seçeneği de var. Dolayısıyla ödüller yalnız üç kutudan ibaret değil.

Part ödülü curse/Ascension'dan geçer; Loot coinleri doğrudan add_coins miktarıdır, pickup coin multiplier yolu değildir. Full-life Repair artık Loot'a ekonomik olarak üstün değil. Bir can eksikte +2'nin bir bölümü MAX5 cap'inde boşa gider.

İlk altı/seçili progression boss defeat evolution credit+1. Core/Sentinel cap flag'leri ayrı açılır. Kapasite artık seçili Core ve erişilebilir Plasma'yı sayar; diğer Core imkânsızsa sayılmaz. Fazla her credit+1reroll+1banish'e dönüşür. Final victory'de credit artması yeni run kart hakkı anlamına gelmez.

### Kill-time: yalnız sayısal referans, ölçüm değil

Altı kontrollü weapon'ın body katkısı kabaca Arc.67HP/sn, RailLv3.35, PulseLv3.21, MortarLv3yaklaşık.25, DroneLv31.09, OrbitalLv3.26. Bunlar aktif, damage kabul eden boss ve controller cycle varsayımıdır; shielding/invulnerability hariç. Fiziksel Plasma/Scatter/Homing isabet oranı bilinmeden gerçek DPS çıkarılamaz.

| BossHP | Etkin2HP/sn | Etkin4HP/sn | Etkin8HP/sn |
|---:|---:|---:|---:|
|100|50sn|25sn|12,5sn|
|145|72,5|36,3|18,1|
|200|100|50|25|
|260|130|65|32,5|
|330|165|82,5|41,3|
|410|205|102,5|51,3|
|500|250|125|62,5|

Bu sütunlar “zayıf/orta/güçlü oyuncunun kesin DPS'si” değildir. Sentinel generator süresi eklenir; A10HP×2,2. Normal sahada çok güçlü AoE build, boss'ta bu düşük katkıya indirgenebilir: özellikle Mortar+Orbital'ın field gücü boss sürelerine taşınmaz. Fireball ball direct3 vsPierce2 de burada doğal asimetri yaratır.

## 14. Save/reset ve görünür bilgi

| State | Run / persistent | Davranış |
|---|---|---|
|Coin|Persistent|Pickup/boss gain ile kaydedilir|
|total_salvage|Persistent|Bank/ölüm kurtarma/harcama ile değişir|
|carried_salvage|Run|Bankta sıfır, ölümde yarısettlement, reset0|
|Paddle owned/selected|Persistent|Yeni run profilden okur|
|Colony level/calibration|Persistent|Config whitelist9type;6slot; calibration≥0|
|Weapon slots/level|Run|Resetempty sonra startweapon|
|Core/evolution/credit|Run|Reset0/none; profile başlangıcı ayrıca|
|Threat|Türetilmiş run|Ayrı save alanı değil|
|XP/currentlevel/fraction|Run|0/1/0; pending0|
|Revive|Run|Kartla1hak; bir kullanım; reset|
|Shield|Run|Her runprofile+Colony'den yeniden|
|Curse|Run|Resetempty|
|Ascension/records|Kısmen persistent|Seçim ve unlocksaved; run_ascension snapshot|

Dosya user://neon_break_meta.cfg. shield_generator/sim_chamber/data_archive whitelist'te. reactor/workshop eski tip kabulü var. **Migration istisnası:** colony_six_slot_migrated false ise bina listesi bir kere temizleniyor. Bu kodda açık, kasıtlı migration; “bütün legacy save'ler hiçbir kayıp olmadan kalır” denemez.

Tam aktif run suspend/resume snapshot'ı yok: weapon/XP/board save edilmiyor. Android uygulaması öldürülürse persistent meta korunması ile aynı run'a devam etmek farklı şeylerdir.

# BALANCE AUDIT

## 15. Ana denge teşhisi

**Kodla desteklenen ana teşhis:** Sorun yalnız HP azlığı veya yalnız spawn yavaşlığı değil; oyuncu clear gücü, doluluk feedback'i ve ödüllü ek üretim birbirine güçlü biçimde bağlı.

- İlk büyük güç sıçraması bedelsiz başlangıç Core/weapon, ilk weapon acquisition ve Plasma/Drone1→2 gibi atış sayısı sıçramalarında.
- İki weapon topun seyahat süresinden bağımsız iki saldırı kaynağıdır; Fireball/Pierce ayrıca topun vuruş başına alanını genişletir. Chain de kill serisiyle büyür.
- Armor2HP, tek AoE vuruşunu durdurabilir; iki örtüşen AoE, Pulse tick'leri veya iki silahın ardışık vuruşunu durdurmaz.
- Threat2–3 promotion'ı yumuşak batch hedefidir; homojen HP artışı değil. Bir Common'dan gelen çoklu atış ile bir Legendary'nin hedef cap'li saldırısı eşit Threat seviyesi taşıyabilir.
- Materialize boş sahaya cevap verir ama maksimum net arz garantisi vermez. Kills>normal+recovery ise bir sonraki cooldown'a kadar yine boş kalır.
- Cooldown'ı çok sıklaştırmak ise 1–2HP kümeleri tekrar tekrar ödüle çevirebilir. %35loot bu döngüyü azaltır, sıfırlamaz.
- Mobile fill target'ın%60–75 olması “az eksik hedefi tamamlama”dan yoğun board üretimine geçiştir. Ball'ın bulunduğu hücre hariç bütün legal alanın dolması, oyuncunun okuyabildiği alanla aynı şey değildir.
- Oyuncunun tehlikeyi kesin kaybettiği Depth koddan belirlenemez. Ball kaybı, yan mermi ve boss tehlikesi board empty olsa bile sürer.

### Güçlü / zayıf olma potansiyeli

Yoğun mobile kümelerinde Fireball+Arc/Mortar güçlü clear adayıdır. Pierce+Rail/Pulse dar koridorlarda güçlüdür. Drone+Homing hareketli hedef/danger cleanup'ta güvenilirdir. Fireball+Mortar+Explosive zinciri tek anda birçok hit/VFX/loot üretir.

Bunlar evrensel sıralama değil, geometry'ye bağlı avantajdır. Orbital düşük hedef cap'i ve uzun bekleme nedeniyle Legendary etiketi kadar screen clear yapmayabilir. Mortar'ın geniş AoE'si Common olmasına rağmen kalabalıkta yüksek değer sağlar. Homing'in iki füzesinin aynı düşükHP hedefe yönelmesi overkill yapabilir; canlı hedef yeniden seçimi bunu her senaryoda sıfırlamaz.

### Economy ve multiplicative etkiler

XP Gain+Data additive, sonra Depth×Curse×Ascension×row-scale. Drop Rate daha fazla orb ihtimaliyle bu gain'e çarpımsal etki eder. Salvage Find×Drop Rate Part chance'ını.42'ye çıkarır; cap1 toplama gecikmesine göre gerçek throughput'u sınırlar.

Fire radius lineer calibration ama dolu 2D saha alanı karesel artabilir. Plasma calibration .98^C interval; uzun vadede attack cadence üstel artar. Shield ve reroll sınırsızcalibration oyuncu ustalığını gölgeleyebilir. Bu buff'ların Threat'e sayılmaması fresh-meta ve veteran build'lerde farklı gerçek zorluk üretir.

### HP'yi ciddi artırmak doğru mu?

**Toplu olarak hayır.** Normal1HP hızlı kırılma hissinin omurgası. Tüm brickleri3–5HP yapmak Arc/tek-hit kontrollü silahı öldürürken Pulse/çokluAoE'yi göreli güçlendirir; boss dışı saha da HP sponge'a döner.

İlk denemede Normal1/Armor2/Elite3–4–5 korunmalı. Ölçüm sürekli boşluk gösterirse yalnız T6+ ve D17+ küçük seçili guard formasyonlarında%10–15 kadar3HP denemesi düşünülebilir; global otomatik artış değil. Bu öneri şu an uygulanmış değildir.

## 16. On dakikalık mobile run: güvenilirlik sınırı

Bu tur gerçek fizik/oyuncu replay'i veya güncel kodun bütün kararlarını çalıştıran harness yürütülmedi. Destroy%85 gibi dışarıdan bir oran vermek materialize geri beslemesini, boss sürelerini ve paddle kaçışını gerçekçi üretmez.

| İstenen metrik | Sonuç |
|---|---|
|10dk ulaşılanDepth/Lv/kart sayısı|GÜVENİLİR ŞEKİLDE SİMÜLE EDİLEMEDİ|
|Ownedweapon/level/Core|GÜVENİLİR ŞEKİLDE SİMÜLE EDİLEMEDİ|
|Ortalama/peakThreat|GÜVENİLİR ŞEKİLDE SİMÜLE EDİLEMEDİ|
|Ortalamaactivebrick/min-maxoccupancy|GÜVENİLİR ŞEKİLDE SİMÜLE EDİLEMEDİ|
|Normalrows/sidewaves/materializeevent ve adet|GÜVENİLİR ŞEKİLDE SİMÜLE EDİLEMEDİ|
|Boss encounters/Coin/Part|GÜVENİLİR ŞEKİLDE SİMÜLE EDİLEMEDİ|

Ölçülebilen statik sonuçlar: XPtablosu, chance/intervalformülleri, configHP, target fill, bazı teorik cycle üst sınırları. Bunlar yukarıda ayrı işaretlendi.

Bir sonraki gerçek ölçüm: freshmeta ve güçlüColony ayrı; aynıpaddle/A0;10dk,3farklırun; boşsaha süresi, danger'a yaklaşım, toplamcard ve boss süresini kaydet. UI duraklamalarını gameplayelapsed'dan ayır. Bu tur telemetry kodu yazılmadı.


# MOBILE AUDIT

## 17. Gerçek mobil farklar

- Portrait mantıksal referans 648×1152, stretch canvas_items. Fiziksel 1080×2400 ile world koordinatları aynı kabul edilmez.
- Safe area fiziksel pencereden logical viewport'a çevrilir; şüpheli dar ölçümlerde minimum genişlik %80, yükseklik %60 kontrolü vardır.
- Slider CanvasLayer kullanır. Rail genişliği %92, yüksekliği56, knob92,16; alt padding50, paddle Y offset−80 ve knob üzerinde44 mesafe. Aim ile slider farklı touch sahipliğine sahiptir.
- Desktop .88 Camera2D ile daha geniş dünya görür. Mobile büyütülmüş brick/top ve5/6 sütun kullanır.
- Mobile normal interval×.82, ilk boss sonrası×.84; desktop açılışı2,05sn ve postboss×.88. Mobile yalnız “daha az brick dolayısıyla kolay” değildir.
- Yeni target-fill yalnız portrait mobile yoludur. Landscape/desktop bunu aynen kullanmaz.
- Normal satır XP'si normalize; recovery XP'si üretim adedine bağlı. Yeni materialize yoğunluğu eski normalizasyon simülasyonunun sonucu değildir.

## 18. Mevcut HUD ve card selection

Kaynak: main.gd _setup_mobile_hud_row(), _apply_mobile_portrait_layout(); mobile_card_info.gd.

Solda canlar; MobileTopRow içinde gerçek XP paneli, Part, Coin ve Pause node'ları vardır. XP minimum120×60/expand, Part80×38, Coin86×38, Pause48×48; aralık6. Kalpler font27, level18, XP16, coin18 logical px. Üst safe margin12/20.

Depth/Combo ayrı alt satırda, eski küçük BuildHUD da mevcut. **CORE EMPTY / REZONANS / S1 / S2 / KALKAN şeridi aktif değil.** Gerçek slotlar ve shield mekaniği duruyor. BuildHUD eski Plasma/Fire/Pierce ve pasif ikon listesidir; dokuz weapon'ı eksiksiz gösteren iki-slot şeridi değildir.

Part label, total_salvage_changed üzerinden **kalıcı kasa** miktarını yazar. Pickup'ın artırdığı carried_salvage bu label'ı anında artırmaz. “Topladım ama sayım değişmedi” hissinin somut kod karşılığı vardır.

Mobil kart düzeni:
- Üstte2, altta1; artwork2:3; tüm blok safe alandaki kalan boşluğun.45'i kadar optik merkezlenir.
- Info slot font metriklerine bağlı sabit yüksekliktedir. İlk frame görünür node/alpha0; focus yalnız metin ve alpha değiştirir.
- Başlık32, açıklama24, SEÇ24, reroll/banish18.
- Açıklama iki satırlık RichText alanında; daha uzunsa scroll olabilir.
- İlk dokunma preview, SEÇ gerçek commit; banish modunda YOK ET.
- CardPool.get_description(nextLevel) kullanılır; PNG statı okunmaz.
- Native panel şu anda yalnız başlık+açıklama gösterir. Kategori/rarity/current→next level ayrıca yazılmaz; portrait slot-state paneli de gizlenir.

HUD choosing_card, pending_card_choices>0 veya pause sürdükçe gizli kalır; coordinator oyunu açınca önceki görünürlüğe döner. Bu tur screenshot/geometry testi yeniden yapılmadı.

Geliştirmeler responsive/scroll yaklaşımı beş paddle seçeneğini korur. Colony platformları oranlı konumlanır; dokuz bina türünün altısı live scene, üçü procedural fallback kullanır.

## 19. Mobil deneyim ve performans

Oyuncu ball, slider, marker'lar, weapon mermileri ve boss uyarısını aynı anda okur. Problem yalnız FPS değil dikkat bütçesidir.

Explosive ağır VFX cap4, Scatter full-VFX limit10; Fireball/Mortar hafifletme ve Architect trail/Chrono spark limitleri var. Damage atlanmıyor. Ancak bunlar ortak bir global bütçe değil: Napalm, Chain, orb'lar ve materialize aynı anda çalışabilir.

Safe-grid adayları brick/ball overlap taramaları yapar; yoğun sahada maliyet cells×bricks yönünde büyür. Fiziksel cihaz profili olmadan kesin FPS/batarya sonucu verilmez. Ortalama FPS kadar p95/p99 frame gecikmesi önemlidir.

Boss reward seçenekleri Bank/Curse ile artabilir; kart ekranının2+1 düzeni bu ayrı UI'a otomatik uygulanmaz. Android uygulama öldürülmesi sonrası run-resume snapshot'ı da yok. Meta kaydının korunması aynı run'a dönebilmek demek değildir.

# TECHNICAL DEBT

## 20. Aktif, eski ve çelişen parçalar

| Bulgu | Gerçek durum |
|---|---|
|paddle_width/paddle_speed/extra_ball|Teklif dışı; helper'ları compatibility/pickup için korunmalı|
|Core Resonance|Aktif meter/proc yok; Crit kartının eski adı ayrı şey|
|Mine Launcher|Aktif pool/registry/runtime bağlantısı yok|
|moving_brick.tscn/.gd|Root'ta legacy çift; güncel generator brick_piece kullanıyor|
|xp_orb_scene değişkeni|Adına rağmen exp_orb.tscn preload ediyor|
|plasma_level|Slot state'in compatibility aynası; bağımsız level kaynağı yapılmamalı|
|get_power_synergy_tier|Threat alias'ı; ikinci skor değil|
|Occupancy|columns×8 ve safe free-grid+active olmak üzere iki payda|
|Side-wave elite yorumu|allow_shield=true çağrısı “yalnız ana row” yorumunu geçersiz kılıyor|
|Toughness yorumu|“materialize unchanged” eski yorum; güncel mobile finish helper'ı çağırıyor|
|AGENTS/GOREVLER sayıları|Eski22kart/8silah/Mine bilgisi güncel kodu tarif etmiyor|
|Motor etiketi|project.godot4.8, AGENTS4.7; test binary'si ayrıca doğrulanmalı|
|Metin encoding|Bazı main/field yorumlarında bozulmuş karakterler mevcut|
|Card data/art/alias|Ayrı ad/açıklama kaynakları zamanla ayrışabilir|
|Debug tuşları|Güncel main debug/release koruması var; eski “korumasız” notu geçersiz|

Diskte eski dosya bulunması active olduğunu kanıtlamaz. Bu audit tüm legacy dosyalar için eksiksiz UID/resource-graph arşivleme izni vermez.

### Duplicate UID doğrulandı

.import metadata çiftleri:

- ball_card.png + assets/cards/ball_card.png → uid://doxsai164uwo4
- plasma_card.png + assets/cards/plasma_card.png → uid://c0h4es3f5qljj
- hit.mp3 + assets/audio/sfx/bricks/brick_hit.mp3 → uid://dhh2ba11tiu1c

Bu tur import çalıştırılmadı; bulgu yeni warning log'una değil dosyadaki kimliklere dayanıyor. Hiçbiri değiştirilmedi.

## 21. Save ve muhasebe borcu

Dokuz bina whitelist'te; önceki üç eksik tip problemi güncel kodda yok. İlk six-slot migration ise bina listesini temizliyor. Zafer Factory bonusunda ölüm settlement'ı reuse edilmesi ayrı, somut bir hata.

Coin/Part gain'lerinde integer yuvarlama erken uygulanır: bir pickup'ta×1,25→1, ×1,5→2 gibi eşikler vardır. “Her pickup %25 daha çok verir” literal olarak doğru değildir.

Boss request-key/cycle sözlüklerinin uzun savaşta büyümesi ve görsel/gerçek boss hit zamanının ayrışması izlenmeli. Bu tur bunlardan crash üretildiği iddia edilmiyor.

# CURRENT RISKS

## 22. En önemli 10 risk

| # | SEVERITY | WHY | PLAYER IMPACT | RELATED SYSTEMS |
|---:|---|---|---|---|
|1|HIGH|%60–75 fill hedefi artık daha büyük safe-grid'e bağlı|Boş saha ile yoğun duvar arasında salınım|Materialize/adaptive|
|2|HIGH|Clear→recovery→ödül→upgrade pozitif döngüsü|Güçlü build daha fazla XP üretip farkı büyütebilir|XP/drop/materialize|
|3|HIGH|Zafer Factory bonusu ölüm settlement'ına giriyor|Kazanılan run'da bonus yarılanıyor|Victory/Colony|
|4|HIGH|HUD yalnız kalıcı kasayı gösteriyor|Pickup kazancı görünmez, ekonomi güveni azalır|Carry/bank/HUD|
|5|HIGH|Altı generic boss hit generator değil core'a gider|Bazı build'lerde Sentinel shield aşaması uzar|Targeting/Sentinel|
|6|HIGH|Sınırsız calibration Threat'e yansımaz|Veteran meta ölüm riskini ve kart RNG'sini aşındırır|Shield/Training/Plasma|
|7|MEDIUM|Core cap2 ama P3 listesi3 açı|Tanımlı ve gerçek pattern ayrışır|boss_core|
|8|MEDIUM|Native infoda level/rarity yok, art metni bağımsız|Yanlış upgrade beklentisi|CardPool/mobile UI|
|9|MEDIUM|Global CPU/VFX bütçesi yok|Yoğun Android frame gecikmesi|AoE/grid/orbs|
|10|MEDIUM|Run resume yok; UID ve sürüm drift'i var|Uzun oturum kaybı, farklı makinede belirsizlik|Save/resources|

Kanıtlanmamış çökmeyi CRITICAL saymadım. Bu audit ne yeni crash ölçümü ne de “release blocker yok” garantisi verir.

# CODEX BAĞIMSIZ TASARIM DEĞERLENDİRMESİ

## 23. Oyun benim olsaydı

Önce özellik sayısını artırmayı bırakır, **topla yönettiğim bir savaş alanı** hissini sağlamlaştırırdım. Dokuz silah/yirmi kart/yedi boss içerik açısından yeterli; sorun güçlenmenin okunabilir bir tehlike ritmine dönüşmesi.

| Öneri | WHY | PLAYER EXPERIENCE | Mevcut bağ | Cost1–5 | Risk1–5 | Impact1–5 |
|---|---|---|---|---:|---:|---:|
|A. Pressure A/B: boş saha süresi, danger-zone brick, kart aralığı|Raw count gerçek tehlike değil|Güçlü kalırken hedef bulur, boğulmaz|Director/materialize|2|1|5|
|B. Victory settlement ve banka/taşınan sunumu|Somut ödül hatası|Kazancına güvenir|Colony/HUD|2|2|5|
|C. Native infoda current→next level satırı|PNG küçük metni yeterli değil|Hızlı/doğru karar|MobileCardInfo|1|1|4|
|D. Recovery için ortak occupancy ve ödül bütçesi|Pressure katmanları aynı işi farklı ölçüyor|Dalga anlaşılır, sonra nefes|Field helpers|3|3|5|
|E. Mevcut bricklerle üç formasyon denemesi|HP yerine hedef önceliği|Topa açı vermenin nedeni olur|Patterns/Shield/Explosive|2|2|4|
|F. Sentinel generator aşamasını ayrı ölç|Body compatibility her aşamayı çözmüyor|Silahının katkısını anlar|Boss/weapon fallback|3|3|4|
|G. Calibration'ın etkisiz/aşırı adımlarını netleştir|Cap sonrası boş harcama ve sınırsız dayanıklılık|Meta bir karar olur|Colony helpers|2|3|4|

Bunlar uygulanmamış önerilerdir. Maliyet göreli mühendislik tahminidir, süre taahhüdü değildir.

## 24. Kimlik ve çıkarma kararı

| Sistem | Kimlik | Karar |
|---|---|---|
|Continuous descending field|CORE IDENTITY|KEEP: zaman baskısı ve top becerisi|
|İki slot + mounted weapons|CORE IDENTITY|KEEP: iki uzmanlık seçimi|
|Ball/Fireball/Pierce|CORE IDENTITY|KEEP: hedef geometrisini belirlesin|
|Kartlar|SUPPORTING|KEEP: build'e yön versin, kusursuz build garanti etmesin|
|Threat|SUPPORTING / SIMPLIFY|Yaklaşık bütçe sinyali, birebir oyuncu cezası değil|
|Side-wave|SUPPORTING|Mevcut yönlü giriş sunumunu koru|
|Materialize|SUPPORTING / SIMPLIFY|Boşluk iyileştirme, sürekli ekran doldurma değil|
|Adaptive karar katmanları|SIMPLIFY / MERGE|Tek bütçe, farklı spawn sunumları|
|Boss|CORE IDENTITY|Top ustalığını test etsin|
|Colony|OPTIONAL / SUPPORTING|İkinci run yönü, sınırsız dayanıklılık yarışı değil|
|Eski Resonance|REMOVE CANDIDATE, zaten inactive|Geri getirmem|
|Retired helper'lar|KEEP compatibility|Referans kanıtı olmadan silmem|

Tek kaldırma hakkım olsa yeni bir aktif silahı değil, yinelenen pressure kararını birleştirirdim. Dokuz silahtan birini çıkarmak için şu an yeterli veri yok.

## 25. Fun ve power fantasy

Güçlü potansiyel: tek brick kırılmasından patlama zincirine geçiş; iki slotun taahhüdü; Fireball alan/Pierce koridor ayrımı; bankalama riski; farklı boss mekanikleri.

Zayıf hissetme riski: hedef bitince bekleme, hemen ardından yoğun refill; topa dikkat etmeden silahların silmesi; sonraki anlamlı kartın geç gelmesi; taşınan Part'ın görünmemesi. Bunlar kodla desteklenen hipotezlerdir, oyuncu zevki ölçümü değildir.

**Güç hissi:** Bir sürüyü doğru açı ve build'le parçalamak.  
**Tehlike:** Aynı anda öncelikli source'u, yaklaşan düşmanı ve ball dönüşünü okumak.

Bu ikisini bütün brick HP'sini dörtleyerek birleştirmem. Director önce temizlemenin ödülünü hissettirmeli, sonra işaretli yeni problemi getirmeli. XP'yi pahalılaştırmak tek başına encounter tasarımı değildir.

## 26. Formation ve brick tasarımı

Önce yeni tür değil mevcut kaynaklar:

| Encounter | Purpose | Counterplay | Synergy | Risk |
|---|---|---|---|---|
|CORRIDOR|Üst arkaya erişim açmak|Paddle ile açıyı yakala|Pierce/Rail/Pulse|Tam kapalı duvar olmasın|
|REACTOR CLUSTER|Öncelikli patlayıcı hedef|Önce Explosive'ı vur|Fire/Arc/Mortar|Ödül/VFX patlaması|
|FORTRESS|Shield source kararı|Yan açı veya source'a odak|Homing/Drone/top|Source erişilemezse sponge|
|SIDE INVASION|Yönsel baskı|Telegraph sonrası yer değiştir|Scatter/Plasma|Ball üstünde aniden doğmamalı|
|ARMORED COLUMN|Az sayıda maliyetli hedef|Delici açı/odak|Pierce/Pulse|Her sütunu zırhlamama|

Bunlar normal row/grid kimlikleri ve mevcut side-wave helper'larıyla kurulabilir; ikinci bir director şart değil.

Yeni türlerden yalnız **Splitter'ı ileride** düşünürdüm: bir kez iki1HP parçaya ayrılır, aynı ödül bütçesini paylaşır. Purpose hedef önceliği; counter daralmadan kırma; synergy Scatter/Fire; risk exponential spawn, bu yüzden tek nesil ve güvenli hücre cap'i zorunlu.

Healer/Commander'ı şimdi geri getirmem: regen/defense mevcut HP/pressure belirsizliğini gizler. Spawner/Parasite recovery'ye yeni döngü ekler. Moving brick ancak sonraki aşamada küçük hareketli hedef çeşitliliği olarak anlamlıdır.

## 27. Weapon/card derinliği

Rail kilitli koridor, Pulse takip koridoru, Mortar yoğun küme, Orbital sınırlı hedef, Drone takip, Homing yönelme, Arc zincir, Scatter fan ve Plasma sürekli paralel atışla gerçekten ayrışıyor. Fakat1HP sürülerin hepsinin anında silinmesi bu farkları görünmezleştirebilir.

İki slotta cluster control + danger cleanup veya corridor + guided seçimi anlamlı. Trade-off'u yüzlerce özel damage bonusuyla değil geometry/menzil/telegraph üzerinden belirginleştirirdim. Teorik36 weapon çifti×2Core=72 temel kombinasyon, otomatik olarak72 farklı deneyim değildir.

Kart kararları:
- Erken ikinci weapon, küçük pasiften genellikle daha büyük anlık çıktı verir.
- XP Gain erken yatırım; geç alınırsa geri ödeme zamanı az.
- Magnet Duration pickup'a bağımlı. Combo Window seri kill build'inde güçlenir.
- Salvage Find cap1 sonrası kağıttaki×3 kazancı garanti etmez.
- Slow Descent baskıyı azaltırken normal row arzını da azaltır; recovery bunu kısmen örter.
- Orbital'ın Common Mortar'dan daha az brick temizlemesi tek başına hata değil; Legendary uzmanlığı anlaşılır olmalı.
- Training calibration ile çok fazla reroll/banish, RNG'nin build çeşitliliği rolünü azaltabilir.

Üç genel uzmanlık yeterli: **alan açma, tehlikeli hedef bitirme, koridor ustalığı.** Yeni Resonance/proc meter'ı önermiyorum.

## 28. Pacing ve boss becerisi

İdeal süreler ölçüm değil tasarım hedefidir. İlk 2dakikada serve/ball açısı öğrenilir,1–3 anlamlı karar verilir. Bazı paddle'lar weapon ile başladığı için herkese sabit “ilk weapon zamanı” dayatılmaz. Midgame ikinci uzmanlık ve ilk Lv2'ler; late game seyrek ama anlamlı kararlar sunmalıdır.

Boss becerileri: Core yöneltilmiş atıştan kaçma; Sentinel generator önceliği; Celestial telegraph boşluğu; Void değişen ball yörüngesi; Sovereign yatay tarama/taban zamanlaması; Architect iki aşamalı kaçış; Chronoform güvenli boşluğa girme.

Bunlar iyi bir temel. Ancak Mortar/Orbital'ın görselden bağımsız otomatik1 body hit'i boss'u silah kimliğinden koparıyor. İlk hedef damage buff değil, gösterilen saldırıyla gerçek hit zamanını eşlemek olmalı.

## 29. Meta ve mobil yaklaşımım

İkinci run'ın nedeni yalnız Part grind değil: başka paddle/Core yönü, başka iki weapon uzmanlığı, formasyon ve bank riskidir. Dokuz bina/altı platform seçim yaratıyor. Sınırsız shield/reroll ise ustalığı gölgeleyebilir; cap'teki Refinery'ye pahalı calibration almak kötü hissettirir.

Mobile'da uzun kesintisiz oturum zorunluluğu istemem. Boss checkpoint'inde güvenli bırakabilme daha sonra değerlidir; mevcut run-resume yok. Önce kaynak/snapshot sınırlarının tasarımı gerekir.

Görsel öncelik: **ball > yakın tehlike > hedef > weapon VFX > dekor.** HUD'u küçültmek yerine bu sıra korunmalı. Gerçek cihazda frame gecikmesi ve tek elle slider/serve geçişi ölçülmeli.

## 30. Beş özgün fikir yeterli

| Fikir | Mevcut combat bağı | Impact | Cost | Risk |
|---|---|---:|---:|---:|
|Açılabilir koridor|Bir brick'i kırmak topa üst arkaya yol açar|5|2|2|
|Tek ödül bütçeli Splitter|Ayrışan hedef ekstra XP üretmez; safe-cell helper kullanır|3|3|3|
|Sektöre özgü formasyon|Enkaz'da reactor cluster, Avcı'da asimetrik boşluk|4|2|2|
|Boss hedef penceresi|Küçük brick grubunu kırmak topu boss'a yönlendirir|4|4|3|
|Clear sonrası nefes|Bir sonraki recovery önceden işaretlenir, başarı hissi kalır|4|2|2|

Quest/battle pass/crafting gibi combat döngüsünden kopuk katman önermiyorum. Bunlar da henüz uygulanmadı.


# IDEAL NEON BREAK

## 31. Tek, tutarlı model

**Neon Break: top kontrolünü merkezde tutan, iki otomatik silahla uzmanlaşılan, iniş baskısı altında formasyon çözülen bir arcade roguelite.**

İlk 2dakika: Oyuncu topu nereye döndüreceğini öğrenir, birkaç hedefi kendisi temizler, ilk kartı aldığı anda farkı görür. Başlangıç paddle'ı build yönünü belirler ama bütün sorunları çözmez.

5.dakika: İki slotta uzmanlık belirginleşir. Bir yoğun grubu çok hızlı siler; başka bir Shield source veya koridor için açı değiştirir. Recovery temizlemesini iptal eden ceza değil, bir sonraki okunabilir encounter olur.

10.dakika: Oyuncu “çok güçlendim” der; fakat bütün ekranı ezberlemiş değildir. Boss'un hedef penceresi, yan tehdit ve tehlike çizgisine yaklaşan seçili grup karar gerektirir. Aynı ekranı daha yüksek HP ile yeniden oynamaz.

Midgame mekanik kombinasyonları artırır; late game yoğunluğu kontrol altında tutarak karar süresini kısaltır. İki silahın her run'da aynı anda garanti Lv3 olması gerekmez. Core evolution gerçek bir kilometre taşıdır.

Güç hissi çok sayıda düşük HP hedefi verimli kırmaktan; korku erişilebilir ama öncelikli tehlikeden gelir. Run çeşitliliği sadece rarity'den değil paddle, iki slot, hedef geometrisi ve seçilen ekonomi riskinden doğar. İkinci run ustalık ve başka çözüm deneme isteğiyle başlar.

## 32. Birlikte dengelenmiş öneri — UYGULANMADI

Aşağıdaki değerler ölçümden geçmiş yeni denge değil, kontrollü A/B test başlangıcıdır. Hepsini aynı anda uygulamayı önermiyorum.

| Alan | Mevcut | Önerilen ilk test |
|---|---|---|
|Normal/Armor/Elite HP|1/2/3–4–5|Aynen koru|
|Seçili ağır formasyon|Global ek3HP yok|Yalnız ihtiyaç kanıtlanırsa D17+,T6+,batch'in%10–15'i3HP; normalglobalHP artışı yok|
|Threat|T0–8, birden çok baskı eksenine bağlı|Formülü koru; aynı T'de gerçek clear farkını ölç; mobile global+adaptive hızın üst üste etkisini ayrı A/B yap|
|Tough target|0/0/.175/.275/.35/.45/.50|İlk testte koru; recovery sayısı değişirken HP'yi aynı anda değiştirme|
|Materialize başlangıcı/hedefi|<.45 → .60–.75|Aynı safe-grid paydasında trigger.30–.35; target.45–.55 bandı|
|Materialize event|max24, minCD1.6|max8–12, minimum2.5–3sn; .7telegraph koru|
|Side-wave|4 veya4+4; ayrı kararlar|Mevcut girişleri koru; materialize ile tek recovery bütçesi, min2sn olay ayrımı|
|Normal row arzı|Depth/floor mevcut|İlk tur değiştirme; temel zaman baskısının referansı kalsın|
|Recovery ödülü|.35chance|İlk testte koru; yalnız recoveryfarm kanıtlanırsa .20–.25 chance test et, normal satır XP'sine dokunma|
|XP curve|1.20 üstel + M(L)|İlk 2kart maliyetini şimdilik koru; geç oyun kart aralığı>120sn ise L8+ M'yi yalnız%10–15 azaltarak ayrı test|
|Elite|D4+,max 1/row,HP3/4/5|Koru; source erişimi ve görsel ayrımı iyileştir|
|Weapon/Core damage|Genel1hit, Core utility|Genel nerf yok; gerçek hit/kill/overkill verisiyle yalnız aykırı family hedeflenir|
|Boss|100→500 + generator|İlk tur HP aynı; Sentinel generator süresini ve gerçek weapon katkısını ayrı ölç|

Ölçülebilir ilk hedefler:
- Normal segmentte tamamen hedefsiz geçen süre toplamın%5'inden az.
- Recovery sonrası10sn içinde, spawn'ın yakın danger bölgesinde yarattığı ani can kaybı olmamalı.
- Mobile safe-grid doluluğu çoğu zamanda .30–.55 arası; “ne kadar doluysa o kadar iyi” hedefi yok.
- Erken kart kararları yaklaşık30–60sn, mid60–90sn, late90–120sn gameplay aralığı hedefi; pause süresi hariç. Bunlar gereksinim formülüne körlemesine çevrilmez.
- Boss hedef süresi Core30–60sn; Sentinel generator dahil60–100sn; late boss75–120sn, orta build/A0. Çok güçlü build daha hızlı bitirebilir. Mevcut gerçek süre olduğu iddia edilmiyor.

A/B ilk olarak **yalnız recovery hedefi ve event bütçesi** üzerinde yapılmalı. XP/HP/damage aynı testte değişirse neden-sonuç kaybolur. Somut ekonomi bug fix'i denge deneyinden ayrı tutulmalı.

# ÖNCELİKLİ ROADMAP

## 33. HIGH IMPACT / LOW COST — en iyi beş

1. Victory Factory settlement'ını ayır: Impact5/Cost2/Risk2. Kesin kaynak bulgusu, oyuncu ödülünü düzeltir.
2. Banka ile taşınan Part bilgisini ayır:5/2/1. Mevcut ekonomik riski anlaşılır yapar.
3. Native kart paneline tek current→next level satırı:4/1/1. Artwork yeniden üretmeden doğru karar sağlar.
4. Aynı kayıt koşullarıyla mobile pressure A/B ölçümü:5/2/1. Yeni dengeyi kör tahminden çıkarır.
5. Mevcut row helper'ıyla üç küçük formasyon:4/2/2. Yeni enemy/HP sistemi yazmadan beceri alanı yaratır.

Bu sıralama uygulanacak onay değildir. Özellikle ilk iki madde bu görevde sadece raporlandı.

## 34. ŞU ANDA YAPMAYIN

1. Bütün brick HP'sini3–5 yapmak: hızlı kırma hissini kaybettirir, çoklu-hit üstünlüğünü artırır.
2. Healer/Commander/Spawner'ı aynı anda geri getirmek: mevcut pressure sorununa yeni döngü ekler.
3. Onuncu weapon veya yeni passive pool'u açmak: dokuz silahın rolü henüz ölçülmedi.
4. XP, düşme oranı, spawn ve weapon damage'i aynı turda değiştirmek: hangi değişikliğin işe yaradığı bilinmez.
5. Yoğunluğu sürekli materialize ve yeni VFX ile maskelemek: boş ekranın yerine performans/okunabilirlik problemi koyar.

## 35. Küçük yol haritası

### ŞİMDİ

1. Victory settlement ve taşınan/kasa gösterimini doğrula/düzelt.
2. Fresh meta ve veteran meta ile üçer10dk fiziksel mobile run kaydet.
3. Mevcut recovery ile düşük-hedef/küçük-event A/B karşılaştır.
4. Card native seviye bilgisi ve Sentinel contribution geri bildirimini netleştir.
5. Aynı davranış korunarak UID/sürüm test baseline'ı belirle; source hash ve gerçek binary kaydı tut.

### SONRA

1. Üç mevcut-brick formasyonu ekle, global HP'yi sabit tut.
2. Field/boss ayrımıyla weapon rolü ve overkill ölç.
3. Calibration cap sonrası değersiz harcama ve sınırsız savunma modelini ele al.
4. Ortak recovery intent/occupancy kavramını sadeleştir.
5. Android p95 frame ve toplam VFX/arama bütçesini profille.

### DAHA SONRA

1. Checkpoint tabanlı güvenli run-resume tasarla.
2. Sektör başına formation karakteri güçlendir.
3. Tek yeni davranış olarak ödül bütçeli Splitter'ı deneyebilirsin.
4. Boss brick→ball hedef pencereleriyle mastery artır.
5. Son dengeye göre artwork/native metin, ses ve localization polish'i tamamla.

# SON KARAR

1. **Ne kadar yakın? 7/10.** Bu kaynak-temelli tasarım olgunluğu puanı; fiziksel oyuncu eğlence testi sonucu değil.
2. **En büyük tek problem:** Oyuncu gücü ile okunabilir encounter baskısı arasındaki kontrolsüz geri besleme.
3. **En güçlü özellik:** Manuel ball kontrolü ile iki otomatik silah uzmanlığının birleşmesi.
4. **Bir sistemi değiştirseydim:** Adaptive/materialize pressure kararını, daha küçük bütçeli ve tek anlamlı occupancy hedefli hâle getirirdim.
5. **Bir yeni özellik ekleseydim:** Mevcut bricklerden açılabilir koridor/öncelikli hedef formasyonları.
6. **Bir sistemi kaldırsaydım:** Ayrı ayrı aynı doluluğa tepki veren yinelenen karar katmanlarını birleştirirdim; aktif silahı silmezdim.
7. **En büyük tasarım riski:** Oyunun top ustalığı yerine otomatik AoE ve sınırsız meta gücüyle çözülen bir ekrana dönüşmesi.
8. **Ana duygu:** “Doğru açı ve doğru build ile bu baskıyı ben parçalıyorum.”
9. **10 saat oynatacak şey:** Yeni sayılardan çok farklı build'lerle farklı formasyon/boss problemlerini ustaca çözmek.
10. **Bir sonraki adım:** Yeni içerik veya genel HP buff'ı değil; gerçek mobile run kayıtlarıyla recovery bütçesini doğrulamak. Victory Factory bug'ı da bağımsız küçük düzeltme olarak öncelikli.

## Denetim izi

İncelenen ana kaynak grupları: main/game_manager; card_pool/card_system/weapon_cards/weapon_system; dokuz weapon controller ve projectile/targeting; ball/paddle/mobile controls; brick_piece/visual/level_generator/continuous field/elite/Shield/Side Attacker; drop/pickup/XP; Colony/save; yedi boss ve ortak boss gövdesi; mobile_card_info/build_hud; sektör/curse/Ascension.

Hesaplar bellekte yapıldı. Dosya oluşturulmadan önce kaydedilen, .git/.godot ve rapor hariç2988 dosyalık içerik özeti:
XI7DVpOyjiKPmp2iP/B6693plaLQmSVNvfomI6w2xKU=

Önceki incelemenin sonundaki ve devam turunun başlangıcındaki aynı kapsamlı özet RKk7zdhqeuPZuwA0A+CWEZRxjkwZiha33KCD31FgGmA= (2988 dosya) oldu. İlk özetle eşleşmediği için önceki oturumun tamamında proje içeriğinin hiç değişmediği hash üzerinden doğrulanmış kabul edilmemelidir. Bu fark tek başına hangi dosyanın, kim tarafından değiştirildiğini göstermez; kaynağı kesinleştirilmeden kullanıcı değişiklikleri geri alınmadı. Analiz çalışması kapsamında yapılan yazımlar yalnız bu rapora yöneliktir.

## Devam turu — tamamlanma durumu

Mevcut rapor korunarak tamamlanma kontrolü yapıldı; bitmiş bölümler baştan analiz edilmedi. İstenen 23 başlığın karşılıkları mevcut: balance/HP/Threat (7–8, 15); materialize/occupancy/side-wave (9–10); ekonomi (12, 14–15, 21); mobile (17–19, 29); technical debt ve riskler (20–22); bağımsız tasarım ve power fantasy (23–25); formation/encounter (26); weapon/build depth (27); card/run pacing ve boss (28); meta progression (29); high-impact/low-cost, yapılmaması gerekenler ve yol haritası (33–35); balance proposal ve ideal model (31–32); son 10 karar sorusu (SON KARAR).

On dakikalık gerçek oynanış sonuçları için durum değişmedi: **GÜVENİLİR ŞEKİLDE SİMÜLE EDİLEMEDİ**. Sayısal kod hesapları gerçek Android run ölçümü olarak sunulmadı. Önerilerin hiçbiri uygulanmadı.

Devam turu başlangıcı: integration/neon-break-unified / b0cf8a0. Önceden var olan 19 tracked değişiklik ve untracked asset/UI dosyaları korundu. Bu tur yalnız raporun denetim/tamamlama notu güncellendi. Kaynak, asset, UI, .import ve export_presets.cfg dosyalarına yazılmadı; Godot import/runtime çalıştırılmadı. Commit, push, merge, rebase, sync ve cleanup yapılmadı.
