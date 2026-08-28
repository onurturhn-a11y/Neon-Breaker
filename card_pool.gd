extends RefCounted
class_name CardPool

# ==================================================
# KART HAVUZU
# ==================================================
# Tek kaynak: kart kimliği, nadirlik, seviye tavanı, görsel ve açıklama.
# Efektler GameManager üzerindeki getter'lardan okunur; burada yalnızca veri durur.
#
# rarity:
#   core   - üç ana silah kartı. Boss milestone'larıyla seviye tavanı açılır.
#   common - küçük ve yığılabilir pasifler.
#   rare   - belirgin etkili pasifler.
#   epic   - run'ı şekillendiren tek seviyelik kartlar.

const RARITY_CORE: StringName = &"core"
const RARITY_COMMON: StringName = &"common"
const RARITY_RARE: StringName = &"rare"
const RARITY_EPIC: StringName = &"epic"

const RARITY_COLORS := {
	RARITY_CORE: Color(0.00, 0.90, 1.00, 1.0),
	RARITY_COMMON: Color(0.54, 0.63, 0.72, 1.0),
	RARITY_RARE: Color(0.72, 0.30, 1.00, 1.0),
	RARITY_EPIC: Color(1.00, 0.48, 0.18, 1.0),
}

const RARITY_LABELS := {
	RARITY_CORE: "ÇEKİRDEK",
	RARITY_COMMON: "YAYGIN",
	RARITY_RARE: "NADİR",
	RARITY_EPIC: "EFSANE",
}

# Silah kartları GameManager'da kendi alanlarında tutulur; pasifler card_levels sözlüğünde.
const WEAPON_CARDS: Array[StringName] = [&"plasma", &"pierce", &"fireball"]

const CARDS := {
	# ---------- ÇEKİRDEK SİLAHLAR ----------
	&"plasma": {
		"title": "PLAZMA SİLAHI",
		"rarity": RARITY_CORE,
		"max_level": 3,
		"roman": true,
		"icon": "res://plasma_card.png",
		"descriptions": [
			"",
			"Rakete otomatik plazma ateşi kazandırır.\nTek namlu otomatik ateş eder.",
			"Rakete otomatik plazma ateşi kazandırır.\nÜç namlu paralel ateş eder.",
			"Rakete otomatik plazma ateşi kazandırır.\nGüçlü yaylı atış yapar; yan mermiler 1 kez seker.",
		],
	},
	&"pierce": {
		"title": "DELİCİ TOP",
		"rarity": RARITY_CORE,
		"max_level": 3,
		"roman": true,
		"icon": "res://assets/cards/piercing_card.png",
		"descriptions": [
			"",
			"Topun tuğlalardan sekmeden geçmesini sağlar.\nRaket dönüşü başına 1 tuğla deler.",
			"Topun tuğlalardan sekmeden geçmesini sağlar.\nRaket dönüşü başına 2 tuğla deler.",
			"Topun tuğlalardan sekmeden geçmesini sağlar.\nRaket dönüşü başına 3 tuğla deler.",
		],
	},
	&"fireball": {
		"title": "ALEV TOPU",
		"rarity": RARITY_CORE,
		"max_level": 3,
		"roman": true,
		"icon": "res://ball_card.png",
		"descriptions": [
			"",
			"İlk tuğla vuruşunda çevresel patlama oluşturur.\nKüçük yarıçaplı patlama.",
			"İlk tuğla vuruşunda çevresel patlama oluşturur.\nOrta yarıçaplı patlama.",
			"İlk tuğla vuruşunda çevresel patlama oluşturur.\nGeniş yarıçaplı patlama.",
		],
	},

	# ---------- YAYGIN PASİFLER ----------
	&"paddle_speed": {
		"title": "SERVO HIZLANDIRICI",
		"rarity": RARITY_COMMON,
		"max_level": 3,
		"roman": true,
		"icon": "res://assets/cards/paddle_speed_card.png",
		"descriptions": [
			"",
			"Raket hareket hızı %12 artar.",
			"Raket hareket hızı toplam %24 artar.",
			"Raket hareket hızı toplam %36 artar.",
		],
	},
	&"paddle_width": {
		"title": "ALAN GENİŞLETİCİ",
		"rarity": RARITY_COMMON,
		"max_level": 3,
		"roman": true,
		"icon": "res://assets/items/icons/horizontal-flip.svg",
		"descriptions": [
			"",
			"Raket genişliği %8 artar.",
			"Raket genişliği toplam %16 artar.",
			"Raket genişliği toplam %24 artar.",
		],
	},
	&"xp_gain": {
		"title": "VERİ EMİLİMİ",
		"rarity": RARITY_COMMON,
		"max_level": 3,
		"roman": true,
		"icon": "res://assets/items/icons/circuitry.svg",
		"descriptions": [
			"",
			"Toplanan XP %20 artar.",
			"Toplanan XP toplam %40 artar.",
			"Toplanan XP toplam %60 artar.",
		],
	},
	&"drop_rate": {
		"title": "TARAMA DİZİSİ",
		"rarity": RARITY_COMMON,
		"max_level": 3,
		"roman": true,
		"icon": "res://assets/items/icons/metal-bar.svg",
		"descriptions": [
			"",
			"Tuğlaların eşya düşürme şansı %25 artar.",
			"Tuğlaların eşya düşürme şansı toplam %50 artar.",
			"Tuğlaların eşya düşürme şansı toplam %75 artar.",
		],
	},
	&"magnet_duration": {
		"title": "ÇEKİM ALANI",
		"rarity": RARITY_COMMON,
		"max_level": 3,
		"roman": true,
		"icon": "res://assets/items/icons/gears.svg",
		"descriptions": [
			"",
			"Mıknatıs süresi %30 uzar.",
			"Mıknatıs süresi toplam %60 uzar.",
			"Mıknatıs süresi toplam %90 uzar.",
		],
	},
	&"combo_window": {
		"title": "ZİNCİR BELLEĞİ",
		"rarity": RARITY_COMMON,
		"max_level": 3,
		"roman": true,
		"icon": "res://assets/items/icons/microchip.svg",
		"descriptions": [
			"",
			"Combo zinciri %25 daha uzun sürer.",
			"Combo zinciri toplam %50 daha uzun sürer.",
			"Combo zinciri toplam %75 daha uzun sürer.",
		],
	},

	# ---------- NADİR PASİFLER ----------
	&"extra_ball": {
		"title": "İKİZ ÇEKİRDEK",
		"rarity": RARITY_RARE,
		"max_level": 2,
		"roman": true,
		"icon": "res://assets/items/icons/striking-balls.svg",
		"descriptions": [
			"",
			"Sahada kalıcı olarak bir top daha bulunur.",
			"Sahada kalıcı olarak iki top daha bulunur.",
		],
	},
	&"crit_hit": {
		"title": "KRİTİK REZONANS",
		"rarity": RARITY_RARE,
		"max_level": 2,
		"roman": true,
		"icon": "res://assets/items/icons/token.svg",
		"descriptions": [
			"",
			"Top vuruşlarının %14'ü çift hasar verir.",
			"Top vuruşlarının %28'i çift hasar verir.",
		],
	},
	&"salvage_find": {
		"title": "HURDA DEDEKTÖRÜ",
		"rarity": RARITY_RARE,
		"max_level": 2,
		"roman": true,
		"icon": "res://assets/items/icons/cog.svg",
		"descriptions": [
			"",
			"PARÇA düşme şansı iki katına çıkar.",
			"PARÇA düşme şansı üç katına çıkar.",
		],
	},
	&"ball_speed": {
		"title": "AŞIRI İVME",
		"rarity": RARITY_RARE,
		"max_level": 2,
		"roman": true,
		"icon": "res://assets/items/icons/bottom-right-3d-arrow.svg",
		"descriptions": [
			"",
			"Top %10 hızlanır. Daha çok tuğla, daha az tepki süresi.",
			"Top toplam %20 hızlanır. Daha çok tuğla, daha az tepki süresi.",
		],
	},

	# ---------- EFSANE ----------
	&"revive": {
		"title": "YEDEK ÇEKİRDEK",
		"rarity": RARITY_EPIC,
		"max_level": 1,
		"roman": false,
		"icon": "res://assets/items/icons/heart-plus.svg",
		"descriptions": [
			"",
			"Run başına bir kez: son canını kaybettiğinde\niki canla ayağa kalkarsın.",
		],
	},
	&"slow_descent": {
		"title": "ZAMAN AĞI",
		"rarity": RARITY_EPIC,
		"max_level": 1,
		"roman": false,
		"icon": "res://assets/items/icons/time-trap.svg",
		"descriptions": [
			"",
			"Tuğla satırlarının iniş hızı kalıcı olarak %15 yavaşlar.",
		],
	},
}


## Havuz = bu dosyadaki kartlar + weapons/weapon_cards.gd kayitlari.
## Codex silah eklerken bu dosyaya dokunmaz.
static func get_ids() -> Array:
	var ids: Array = CARDS.keys()
	ids.append_array(WeaponCards.CARDS.keys())
	return ids


static func has_card(card_id: StringName) -> bool:
	return CARDS.has(card_id) or WeaponCards.CARDS.has(card_id)


static func get_data(card_id: StringName) -> Dictionary:
	if WeaponCards.CARDS.has(card_id):
		return WeaponCards.CARDS[card_id]
	return CARDS.get(card_id, {})


## Yuva isgal eden silah karti mi? (Cekirdek uc silahtan farkli.)
static func is_mounted_weapon(card_id: StringName) -> bool:
	return bool(get_data(card_id).get("weapon", false))


## Kartin gosterilecek seviyesi. Monteli silahlar yuva sisteminden okunur.
static func get_display_level(gm: Node, card_id: StringName) -> int:
	if is_mounted_weapon(card_id):
		return WeaponCards.get_level(gm, card_id)
	return gm.get_card_level(card_id) if gm != null else 0


static func get_title(card_id: StringName) -> String:
	return String(get_data(card_id).get("title", "?"))


static func get_rarity(card_id: StringName) -> StringName:
	return get_data(card_id).get("rarity", RARITY_COMMON)


static func get_rarity_color(card_id: StringName) -> Color:
	return RARITY_COLORS.get(get_rarity(card_id), Color.WHITE)


static func get_rarity_label(card_id: StringName) -> String:
	return String(RARITY_LABELS.get(get_rarity(card_id), ""))


static func get_max_level(card_id: StringName) -> int:
	return int(get_data(card_id).get("max_level", 1))


static func uses_roman_numeral(card_id: StringName) -> bool:
	return bool(get_data(card_id).get("roman", false))


static func get_icon_path(card_id: StringName) -> String:
	return String(get_data(card_id).get("icon", ""))


static func get_description(card_id: StringName, level: int) -> String:
	var descriptions: Array = get_data(card_id).get("descriptions", [])
	var index := clampi(level, 0, descriptions.size() - 1)
	if index < 0:
		return ""
	return String(descriptions[index])


static func is_weapon(card_id: StringName) -> bool:
	return card_id in WEAPON_CARDS
