extends RefCounted
class_name CardSystem

# ==================================================
# KART KURALLARI
# ==================================================
# Kart ekranının KARAR katmanı: hangi kart uygun, hangi ağırlıkla çıkar,
# elde hangi üç kart olur. Görsel kısım main.gd'de kalır.
#
# Bu ayrımın sebebi: silah/yuva sistemi yalnızca bu kurallara dokunmak
# zorunda. Codex yuva sınırını buraya değil, weapon_cards.gd'ye yazar;
# burası yalnızca ona sorar. Böylece iki ajan main.gd'de çakışmaz.
#
# ÖNEMLİ: Buradaki fonksiyonlar saf (pure) tutulmuştur — autoload'a
# doğrudan erişmezler. Godot, class_name script'lerini autoload'lar
# kaydolmadan önce derleyebildiği için static gövdeden `GameManager`
# çağırmak "Identifier not found" hatası verir. Bu yüzden çalışma durumu
# `state` parametresiyle dışarıdan geçirilir.

## main.gd bu sözlüğü üretip kural fonksiyonlarına verir.
static func make_state(
	game_manager: Node,
	first_boss_defeated: bool,
	second_boss_defeated: bool
) -> Dictionary:
	return {
		"gm": game_manager,
		"depth": int(game_manager.run_depth),
		"first_boss": first_boss_defeated,
		"second_boss": second_boss_defeated,
	}


## ASCENSION HASAR TAVANI (Faz 6.2)
##
## Ascension boss HP'sini katman başına %12 artırıyordu ama oyuncunun hasar
## tavanını hiç artırmıyordu — kartların max_level'ı sabit. Chronoform asc0'da
## 500 HP, asc10'da 1100 HP; karşısında birebir aynı maksimum build.
##
## Bu kartlar ascension eşiklerinde +1 max_level alır. Silahlar DEĞİL:
## silah seviyesi başına davranış her controller'da ayrı tanımlı (Codex
## bölgesi), Lv4'ün ne yapacağına o karar vermeli.
const ASCENSION_SCALED_CARDS: Array[StringName] = [
	&"crit_hit", &"extra_ball", &"ball_speed",
]

## Kaç ascension katmanında +1 tavan, ve en fazla kaç.
##
## NEDEN BU SAYILAR (ölçüldü): bağlayıcı kısıt tavan değil, SEÇİM ARZI.
## Ascension kazancı +%15/katman ama XP ihtiyacı üstel (×1.20/seviye), yani
## ×2.5 gelir ancak ~4 fazla seviye satın alıyor:
##
##   asc0  -> 21 seçim     asc5  -> 24 seçim     asc10 -> 25 seçim
##
## Entegrasyon: ek tavan yalnız yukarıdaki üç pasif karta uygulanır.
## Fireball/Pierce Core tavanı boss milestone'larıyla Lv1/Lv2/Lv3 kalır.
## Mounted weapon tavanı da Lv3'tür; Ascension bunu değiştirmez.
const ASCENSION_LEVEL_BONUS_PER := 5
const ASCENSION_LEVEL_BONUS_MAX := 2


## Bu kart ascension sayesinde kaç ek seviye kazanıyor?
static func get_ascension_level_bonus(card_id: StringName, state: Dictionary) -> int:
	if card_id not in ASCENSION_SCALED_CARDS:
		return 0
	var gm: Node = state.get("gm")
	if gm == null:
		return 0
	return mini(
		int(gm.run_ascension) / ASCENSION_LEVEL_BONUS_PER,
		ASCENSION_LEVEL_BONUS_MAX
	)


## Silah kartlarının seviye tavanı boss milestone'larıyla açılır.
static func get_weapon_level_cap(state: Dictionary) -> int:
	if bool(state.get("second_boss", false)):
		return 3
	if bool(state.get("first_boss", false)):
		return 2
	return 1


static func get_card_level_cap(card_id: StringName, state: Dictionary) -> int:
	# Core modules retain boss-gated Lv1/Lv2/Lv3; Ascension scales passives only.
	var bonus := get_ascension_level_bonus(card_id, state)
	var pool_cap: int = CardPool.get_max_level(card_id) + bonus
	var gm: Node = state.get("gm")
	if gm != null and (CardPool.is_mounted_weapon(card_id) or card_id in [&"fireball", &"pierce"]):
		pool_cap = mini(pool_cap, gm.get_card_unlock_level(card_id))
	if CardPool.is_weapon(card_id):
		return mini(pool_cap, get_weapon_level_cap(state) + bonus)
	return pool_cap


static func is_card_eligible(card_id: StringName, state: Dictionary) -> bool:
	if not CardPool.has_card(card_id):
		return false
	var gm: Node = state.get("gm")
	if gm == null:
		return false
	if gm.banished_cards.has(card_id):
		return false
	# Core modules are alternatives; upgrades of the selected Core remain eligible.
	if card_id == &"fireball" and gm.get_card_level(&"pierce") > 0:
		return false
	if card_id == &"pierce" and gm.get_card_level(&"fireball") > 0:
		return false
	# Monteli silahlar GameManager.weapon_slots üzerinden yönetilir:
	# hem yuva doluluğu hem seviye tavanı orada kontrol edilir.
	if CardPool.is_mounted_weapon(card_id):
		return WeaponCards.can_offer(gm, card_id)
	return gm.get_card_level(card_id) < get_card_level_cap(card_id, state)


static func get_eligible_card_ids(state: Dictionary) -> Array:
	var eligible: Array = []
	for card_id: StringName in CardPool.get_ids():
		if is_card_eligible(card_id, state):
			eligible.append(card_id)
	return eligible


static func get_rarity_weight(rarity: StringName, state: Dictionary) -> float:
	var depth := int(state.get("depth", 1))
	var gm: Node = state.get("gm")
	match rarity:
		CardPool.RARITY_CORE:
			# İlk iki silah alınana kadar çekirdek kartlar baskın gelsin.
			var weapons: int = (gm.get_active_weapon_count() + gm.get_active_core_count()) if gm != null else 0
			return 48.0 if weapons < 2 else 24.0
		CardPool.RARITY_COMMON:
			return 34.0
		CardPool.RARITY_RARE:
			return minf(15.0 + float(depth) * 0.65, 34.0)
		CardPool.RARITY_EPIC:
			return minf(4.0 + float(depth) * 0.30, 14.0)
		CardPool.RARITY_LEGENDARY:
			return minf(1.5 + float(depth - 1) * 0.10, 4.0)
	return 1.0


## Sahip olunan Legendary silahın Lv2/Lv3 yükseltmesi daha görünür olur.
## İlk edinme ağırlığı değişmez; Lv3 kart zaten eligibility'de elenir.
static func get_card_weight(card_id: StringName, state: Dictionary) -> float:
	var weight := get_rarity_weight(CardPool.get_rarity(card_id), state)
	if CardPool.get_rarity(card_id) != CardPool.RARITY_LEGENDARY:
		return weight
	if not CardPool.is_mounted_weapon(card_id):
		return weight
	var gm: Node = state.get("gm")
	if gm == null:
		return weight
	var level := WeaponCards.get_level(gm, card_id)
	if level > 0 and level < CardPool.get_max_level(card_id):
		return weight * 4.0
	return weight


static func roll_card_ids(count: int, state: Dictionary) -> Array:
	var candidates := get_eligible_card_ids(state)
	var rolled: Array = []
	while rolled.size() < count and not candidates.is_empty():
		var picked_index := _pick_weighted_index(candidates, state)
		rolled.append(candidates[picked_index])
		candidates.remove_at(picked_index)
	return rolled


static func _pick_weighted_index(candidates: Array, state: Dictionary) -> int:
	var total_weight := 0.0
	for card_id: StringName in candidates:
		total_weight += get_card_weight(card_id, state)
	if total_weight <= 0.0:
		return candidates.size() - 1
	var target := randf() * total_weight
	var running := 0.0
	for index in range(candidates.size()):
		running += get_card_weight(candidates[index], state)
		if target <= running:
			return index
	return candidates.size() - 1
