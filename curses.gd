extends RefCounted
class_name Curses

# ==================================================
# LANET SİSTEMİ
# ==================================================
# Gönüllü zorluk. Oyuncu boss ödül ekranında lanet kabul edebilir; karşılığında
# kalıcı bir kazanç çarpanı alır. Cezayı oyuncu SEÇTİĞİ için baskı ödül gibi
# hissedilir — Faz 4'te kaldırılan build cezasının yerini alan şey budur.
#
# Faz 4 kararı: zorluk ya derinlikten gelir ya oyuncunun kendi tercihinden.
# Oyuncunun iyi oynamasından ASLA gelmez.
#
# NOT: static gövdeden autoload çağrılmaz; durum parametreyle gelir.

const CURSES := {
	&"haste": {
		"name": "ACELE LANETİ",
		"description": "Satırlar %12 daha hızlı iner.",
		"reward": "Tüm kazanç +%25",
		"descent_scale": 0.88,
		"armor_bonus": 0.0,
		"attacker_scale": 1.0,
		"life_cost": 0,
		"gain_multiplier": 0.25,
	},
	&"armor": {
		"name": "ZIRH LANETİ",
		"description": "Zırhlı tuğla oranı %10 artar.",
		"reward": "Tüm kazanç +%25",
		"descent_scale": 1.0,
		"armor_bonus": 0.10,
		"attacker_scale": 1.0,
		"life_cost": 0,
		"gain_multiplier": 0.25,
	},
	&"hunted": {
		"name": "AV LANETİ",
		"description": "Yan taretler %35 daha sık ateş eder.",
		"reward": "Tüm kazanç +%25",
		"descent_scale": 1.0,
		"armor_bonus": 0.0,
		"attacker_scale": 0.65,
		"life_cost": 0,
		"gain_multiplier": 0.25,
	},
	&"frail": {
		"name": "KIRILGAN ÇEKİRDEK",
		"description": "Bir can kaybedersin.",
		"reward": "Tüm kazanç +%40",
		"descent_scale": 1.0,
		"armor_bonus": 0.0,
		"attacker_scale": 1.0,
		"life_cost": 1,
		"gain_multiplier": 0.40,
	},
}


static func get_ids() -> Array:
	return CURSES.keys()


static func get_data(curse_id: StringName) -> Dictionary:
	return CURSES.get(curse_id, {})


static func get_name(curse_id: StringName) -> String:
	return String(get_data(curse_id).get("name", "?"))


static func get_description(curse_id: StringName) -> String:
	return String(get_data(curse_id).get("description", ""))


static func get_reward_text(curse_id: StringName) -> String:
	return String(get_data(curse_id).get("reward", ""))


static func get_life_cost(curse_id: StringName) -> int:
	return int(get_data(curse_id).get("life_cost", 0))


## Aktif lanetlerin birleşik iniş hızı çarpanı.
static func get_descent_scale(active: Dictionary) -> float:
	var scale := 1.0
	for curse_id: StringName in active.keys():
		scale *= float(get_data(curse_id).get("descent_scale", 1.0))
	return scale


static func get_armor_bonus(active: Dictionary) -> float:
	var bonus := 0.0
	for curse_id: StringName in active.keys():
		bonus += float(get_data(curse_id).get("armor_bonus", 0.0))
	return bonus


static func get_attacker_scale(active: Dictionary) -> float:
	var scale := 1.0
	for curse_id: StringName in active.keys():
		scale *= float(get_data(curse_id).get("attacker_scale", 1.0))
	return scale


## Lanet başına birikimli kazanç çarpanı (PARÇA, coin, XP).
static func get_gain_multiplier(active: Dictionary) -> float:
	var multiplier := 1.0
	for curse_id: StringName in active.keys():
		multiplier += float(get_data(curse_id).get("gain_multiplier", 0.0))
	return multiplier


## Henüz alınmamış lanetlerden rastgele biri.
static func pick_offer(active: Dictionary, lives: int) -> StringName:
	var candidates: Array = []
	for curse_id: StringName in CURSES.keys():
		if active.has(curse_id):
			continue
		# Son canını alacak laneti teklif etme.
		if get_life_cost(curse_id) > 0 and lives <= 1:
			continue
		candidates.append(curse_id)
	if candidates.is_empty():
		return &"none"
	return candidates[randi() % candidates.size()]
