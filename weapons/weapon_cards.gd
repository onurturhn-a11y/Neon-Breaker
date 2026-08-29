extends RefCounted
class_name WeaponCards

# ==================================================
# SİLAH KARTLARI
# ==================================================
# Silah/yuva sisteminin kart VERİSİ. CardPool bunu çalışma anında kendi
# havuzuyla birleştirir, yani buraya kart eklemek için card_pool.gd'ye
# dokunmak gerekmez.
#
# Silah seviyeleri GameManager.weapon_slots içinde tutulur (Codex sistemi);
# card_levels sözlüğünde DEĞİL. Bu yüzden seviye sorguları
# GameManager.get_weapon_level() üzerinden gider.
#
# NOT: `gm` parametresi GameManager düğümüdür. Static gövdeden autoload'a
# doğrudan erişilemez (Godot sınıfı autoload'lar kaydolmadan derleyebilir),
# bu yüzden dışarıdan geçirilir.

const CARDS := {
	&"plasma": {
		"title": "PLAZMA SİLAHI",
		"rarity": &"common",
		"max_level": 3,
		"roman": true,
		"weapon": true,
		"weapon_id": &"PLASMA",
		"icon": "res://assets/cards/plasma_card.png",
		"descriptions": [
			"",
			"Rakete otomatik plazma ateşi kazandırır. Tek namlu ateş eder.",
			"Üç namlu paralel ateş eder.",
			"Güçlü yaylı atış yapar; yan mermiler 1 kez seker.",
		],
	},
	&"arc_cannon": {
		"title": "ARC CANNON",
		"rarity": &"rare",
		"max_level": 3,
		"roman": true,
		"weapon": true,
		"weapon_id": &"ARC_CANNON",
		"icon": "res://assets/cards/plasma_card.png",
		"descriptions": [
			"",
			"Vurduğu tuğladan komşularına elektrik sıçratır.",
			"Sıçrama menzili ve hedef sayısı artar.",
			"Zincir daha uzun sürer ve daha çok tuğlaya ulaşır.",
		],
	},
	&"scatter_cannon": {
		"title": "SCATTER CANNON",
		"rarity": &"common",
		"max_level": 3,
		"roman": true,
		"weapon": true,
		"weapon_id": &"SCATTER_CANNON",
		"icon": "res://assets/cards/plasma_card.png",
		"descriptions": [
			"",
			"Yelpaze şeklinde küçük mermiler yollar.",
			"Daha çok mermi, daha geniş yelpaze.",
			"En yoğun yelpaze; yakın menzilde ezici.",
		],
	},
	&"railgun": {
		"title": "RAILGUN",
		"rarity": &"rare",
		"max_level": 3,
		"roman": true,
		"weapon": true,
		"weapon_id": &"RAILGUN",
		"icon": "res://assets/cards/plasma_card.png",
		"descriptions": [
			"",
			"Dikey ince ışın; aynı sütundaki tuğlaları deler.",
			"Işın daha hızlı şarj olur ve daha çok tuğla deler.",
			"Tam sütun delme; en yüksek tek hedef hasarı.",
		],
	},
	&"homing_missile": {
		"title": "HOMING MISSILE",
		"rarity": &"rare",
		"max_level": 3,
		"roman": true,
		"weapon": true,
		"weapon_id": &"HOMING_MISSILE",
		"icon": "res://assets/cards/ball_card.png",
		"descriptions": [
			"",
			"En yakın tuğlayı takip eden füze yollar.",
			"Daha sık ateş eder, takip keskinleşir.",
			"Çoklu füze; tehlike çizgisine yakın hedefleri önceler.",
		],
	},
	&"pulse_laser": {
		"title": "PULSE LASER",
		"rarity": &"rare",
		"max_level": 3,
		"roman": true,
		"weapon": true,
		"weapon_id": &"PULSE_LASER",
		"icon": "res://assets/cards/plasma_card.png",
		"descriptions": [
			"",
			"Periyodik olarak kısa süreli sürekli ışın açar.",
			"Işın daha uzun sürer ve daha sık gelir.",
			"Neredeyse kesintisiz ışın; sürekli hasar yığar.",
		],
	},
	&"mine_launcher": {
		"title": "MINE LAUNCHER",
		"rarity": &"common",
		"max_level": 3,
		"roman": true,
		"weapon": true,
		"weapon_id": &"MINE_LAUNCHER",
		"icon": "res://assets/cards/plasma_card.png",
		"controller_script": "res://mine_launcher_controller.gd",
		"controller_node": "MineLauncherController",
		"descriptions": [
			"",
			"Orta sahaya mayın yollar. En fazla 2 mayın; 4 saniye bekleme.",
			"En fazla 3 mayın. Patlama alanı %20 büyür; bekleme 3,6 saniyeye iner.",
			"Yakındaki aktif mayınlar zincirleme patlar; bekleme 3,3 saniyeye iner.",
		],
	},
	&"mortar": {
		"title": "MORTAR",
		"rarity": &"common",
		"max_level": 3,
		"roman": true,
		"weapon": true,
		"weapon_id": &"MORTAR",
		"icon": "res://assets/cards/ball_card.png",
		"controller_script": "res://mortar_controller.gd",
		"controller_node": "MortarController",
		"descriptions": [
			"",
			"Üstteki yoğun tuğla kümelerine 4,5 saniyede bir ağır mermi yollar.",
			"Patlama alanı %25 büyür; yoğun kümeleri daha güçlü önceler.",
			"3,8 saniyede bir kısa aralıklı çift bombardıman yapar.",
		],
	},
}


## Bir kart kimliğinin GameManager'daki silah kimliği karşılığı.
static func get_weapon_id(card_id: StringName) -> StringName:
	return CARDS.get(card_id, {}).get("weapon_id", &"")


## Rakette kaç silah yuvası olduğunu bildirir.
static func get_mount_capacity(gm: Node) -> int:
	if gm == null:
		return 0
	return int(gm.MAX_WEAPON_SLOTS)


## Şu an kaç yuvanın dolu olduğu.
static func get_used_mounts(gm: Node) -> int:
	if gm == null:
		return 0
	return get_mount_capacity(gm) - _count_empty_slots(gm)


static func _count_empty_slots(gm: Node) -> int:
	var empty := 0
	for slot in gm.weapon_slots:
		if StringName(slot.get("weapon_id", &"")) == &"":
			empty += 1
	return empty


## Yuvalar doluysa yeni silah kartı teklif edilmez.
static func has_free_mount(gm: Node) -> bool:
	return gm != null and gm.has_empty_weapon_slot()


## Kart havuzu bu silahı hâlâ teklif edebilir mi?
static func can_offer(gm: Node, card_id: StringName) -> bool:
	if gm == null:
		return false
	var weapon_id := get_weapon_id(card_id)
	if weapon_id == &"":
		return false
	return gm.can_acquire_weapon(weapon_id)


## Silahın mevcut seviyesi (yuva sisteminden okunur).
static func get_level(gm: Node, card_id: StringName) -> int:
	if gm == null:
		return 0
	var weapon_id := get_weapon_id(card_id)
	if weapon_id == &"":
		return 0
	return gm.get_weapon_level(weapon_id)
