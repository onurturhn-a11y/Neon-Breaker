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
	if new_level > 0:
		ensure_runtime_controller(game, card_id)
		if weapon_id == &"PLASMA":
			var paddle := game.get_node_or_null("Paddle")
			if is_instance_valid(paddle) and paddle.has_method("apply_plasma_level"):
				paddle.call("apply_plasma_level", new_level, true)
	print("WEAPON ACQUIRED: %s -> Lv%d" % [weapon_id, new_level])


## Veri kaydında controller tanımlayan yeni silahları main.gd'ye hard-code etmeden kurar.
## Eski silahların mevcut main.gd controller akışı değişmeden kalır.
static func ensure_runtime_controller(game: Node, card_id: StringName) -> void:
	var card: Dictionary = WeaponCards.CARDS.get(card_id, {})
	var script_path := String(card.get("controller_script", ""))
	var node_name := String(card.get("controller_node", ""))
	if script_path.is_empty() or node_name.is_empty():
		return
	var existing := game.get_node_or_null(NodePath(node_name))
	if is_instance_valid(existing):
		return
	if not ResourceLoader.exists(script_path):
		push_error("Weapon controller bulunamadi: %s" % script_path)
		return
	var controller_script := load(script_path) as Script
	if controller_script == null:
		push_error("Weapon controller script yuklenemedi: %s" % script_path)
		return
	var paddle := game.get_node_or_null("Paddle") as Node2D
	if not is_instance_valid(paddle):
		push_error("Weapon controller icin Paddle bulunamadi: %s" % node_name)
		return
	var controller := controller_script.new() as Node
	controller.name = node_name
	game.add_child(controller)
	controller.call("configure", game, paddle)
