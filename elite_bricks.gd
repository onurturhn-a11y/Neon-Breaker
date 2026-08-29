extends RefCounted
class_name EliteBricks

## ==================================================
## ELİT TUĞLA
## ==================================================
##
## Faz 4 risk mekaniklerinin üçüncü ayağı (lanet ve kasa `curses.gd` /
## `game_manager.gd` içinde).
##
## Elit tuğla: yüksek can + belirgin görsel + değerli düşürme.
## Oyuncuya "bunu kırmaya değer mi?" sorusunu sordurur — kırmak zaman ve
## can riski, kırmamak satırın dolu kalması demek.
##
## TASARIM KURALI (Faz 4.1'den devam): oran **derinliğe** bağlıdır, oyuncunun
## build gücüne DEĞİL. Güçlendiğin için cezalandırılmazsın; derine indiğin için
## zorlanırsın.
##
## NOT: Bu dosya `class_name` taşıdığı için `static func` içinden autoload
## çağıramaz (Godot autoload'ları kaydetmeden derleyebiliyor). Gerekli değerler
## parametre olarak geçirilir — `card_system.gd` ve `weapons/weapon_cards.gd`
## aynı deseni kullanır.

## Elit tuğlaların görünmeye başladığı derinlik. Öncesi öğrenme alanı.
const FIRST_ELITE_DEPTH := 4

## DİKKAT — bu oranlar TUĞLA başınadır, satır başına değil.
## Bir satırda 13'e kadar aday tuğla var; tuğla başına oran satır boyunca
## birikir. Satır oranı yaklaşık: 1 - (1 - p) ^ aday_sayısı
##
## Kalibrasyon hedefi (13 sütunluk en kötü durum, `_elite_probe.gd` ile ölçüldü):
##   derinlik  4 → satırların ~%12'si
##   derinlik 12 → satırların ~%30'u
##   derinlik 20+ → satırların ~%45'i
##
## Gerçek satırlar 13 değil ~6-12 aday taşır (doluluk 0.45-0.95) ve özel
## tuğlalar rulete girmez; yani sahadaki oran bu hedeflerin altında kalır.
## Elit bir "olay" olarak kalmalı, norm olmamalı.

## Derinlik FIRST_ELITE_DEPTH'e ulaştığında taban oran.
const BASE_CHANCE := 0.010

## Her ek derinlik için artış.
const CHANCE_PER_DEPTH := 0.0022

## Derinlikten gelebilecek en yüksek oran.
const MAX_DEPTH_CHANCE := 0.045

## Her ascension katmanı oranı bu kadar artırır.
const CHANCE_PER_ASCENSION := 0.004

## Ascension dahil mutlak tavan.
const ABSOLUTE_MAX_CHANCE := 0.065

## Satır başına en fazla bir elit. Dört elitli bir satır oynanabilir değil.
const MAX_PER_ROW := 1

## Elit düşürme çarpanı. "Değerli düşürme" şartı buradan gelir.
const DROP_MULTIPLIER := 3.0

## Elit gövde rengi — Codex'in eklediği RARITY_LEGENDARY kehribarıyla aynı.
const ELITE_BORDER_COLOR := Color(1.00, 0.76, 0.12, 1.0)
const ELITE_GLOW_COLOR := Color(1.00, 0.86, 0.35, 1.0)

## Nabız efektinin tam turu (saniye).
const PULSE_PERIOD := 1.1


## Verilen derinlik ve ascension katmanı için elit çıkma olasılığı.
## Derinlik FIRST_ELITE_DEPTH altındaysa 0 döner.
static func get_chance(depth: int, ascension: int = 0) -> float:
	if depth < FIRST_ELITE_DEPTH:
		return 0.0
	var depth_chance: float = minf(
		BASE_CHANCE + float(depth - FIRST_ELITE_DEPTH) * CHANCE_PER_DEPTH,
		MAX_DEPTH_CHANCE
	)
	var total: float = depth_chance + float(maxi(ascension, 0)) * CHANCE_PER_ASCENSION
	return clampf(total, 0.0, ABSOLUTE_MAX_CHANCE)


## Elit tuğlanın canı. Zırhlı 2 canlıdır; elit her zaman onun üstündedir.
static func get_health(depth: int) -> int:
	if depth >= 20:
		return 5
	if depth >= 12:
		return 4
	return 3


## Elit tuğla bu derinlikte hiç çıkabilir mi? Üretim tarafındaki erken çıkış.
static func is_active_at_depth(depth: int) -> bool:
	return depth >= FIRST_ELITE_DEPTH
