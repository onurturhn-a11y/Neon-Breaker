extends RefCounted
class_name WeaponCards

# ==================================================
# SİLAH KARTLARI — CODEX BÖLGESİ
# ==================================================
# Bu dosya silah/yuva sisteminin kart VERİSİNİ tutar.
# CardPool bunu çalışma anında kendi havuzuyla birleştirir, yani
# buraya kart eklemek için card_pool.gd'ye dokunmak GEREKMEZ.
#
# Kayıt biçimi card_pool.gd'deki CARDS ile birebir aynıdır:
#   &"railgun": {
#       "title": "RAILGUN",
#       "rarity": CardPool.RARITY_RARE,
#       "max_level": 3,
#       "roman": true,
#       "icon": "res://assets/cards/railgun_card.png",
#       "descriptions": ["", "Lv1 metni", "Lv2 metni", "Lv3 metni"],
#   }
#
# Ek olarak silah kartları şunu taşır:
#   "weapon": true      -> yuva işgal eder, CardPool.is_weapon_card() true döner
#
# Yuva sınırı ve ateşleme davranışı weapon_system.gd'de tanımlanır.

const CARDS := {}


## Rakette kaç silah yuvası olduğunu bildirir.
## Üçüncü yuvayı açan kart alındığında bu değer 3 dönmelidir.
##
## NOT: `gm` parametresi GameManager düğümüdür. Static gövdeden autoload'a
## doğrudan erişilemez (Godot sınıfı autoload'lar kaydolmadan derleyebilir),
## bu yüzden dışarıdan geçirilir.
static func get_mount_capacity(gm: Node) -> int:
	var base_capacity := 2
	if gm != null and gm.get_card_level(&"weapon_mount_3") > 0:
		base_capacity += 1
	return base_capacity


## Şu an kaç yuvanın dolu olduğu.
static func get_used_mounts(gm: Node) -> int:
	if gm == null:
		return 0
	var used := 0
	for card_id: StringName in CARDS.keys():
		if gm.get_card_level(card_id) > 0:
			used += 1
	return used


## Yuvalar doluysa yeni silah kartı teklif edilmez.
static func has_free_mount(gm: Node) -> bool:
	return get_used_mounts(gm) < get_mount_capacity(gm)
