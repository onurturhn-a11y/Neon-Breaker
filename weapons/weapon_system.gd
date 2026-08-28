extends RefCounted
class_name WeaponSystem

# ==================================================
# SİLAH SİSTEMİ
# ==================================================
# main.gd, bir kart seçildiğinde önce buraya sorar:
#
#     if WeaponSystem.handles(card_id):
#         WeaponSystem.apply(self, card_id, next_level)
#
# Silah davranışı Codex'in kontrolcülerinde (railgun_controller.gd vb.)
# yaşar; buradaki iş yalnızca kartı GameManager'ın yuva sistemine
# bağlamaktır.


## Bu kart silah sisteminin sorumluluğunda mı?
static func handles(card_id: StringName) -> bool:
	return WeaponCards.CARDS.has(card_id)


## Kart seçildiğinde çağrılır.
## game: main.gd düğümü — paddle ve kontrolcüler buradan erişilir.
static func apply(game: Node, card_id: StringName, _level: int) -> void:
	if not handles(card_id):
		return
	var weapon_id := WeaponCards.get_weapon_id(card_id)
	if weapon_id == &"":
		return
	# Yuva sistemi seviyeyi kendi hesaplar; kontrolcüler oradan okur.
	var new_level: int = game.get_node("/root/GameManager").acquire_or_upgrade_weapon(weapon_id)
	print("WEAPON ACQUIRED: %s -> Lv%d" % [weapon_id, new_level])
