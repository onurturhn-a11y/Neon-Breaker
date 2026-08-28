extends RefCounted
class_name WeaponSystem

# ==================================================
# SİLAH SİSTEMİ — CODEX BÖLGESİ
# ==================================================
# main.gd, bir kart seçildiğinde önce buraya sorar:
#
#     if WeaponSystem.handles(card_id):
#         WeaponSystem.apply(self, card_id, next_level)
#
# Yani silah davranışını eklemek için main.gd'ye dokunmak GEREKMEZ;
# bu dosyayı doldurmak yeterlidir.
#
# Şu an iskelet halinde: handles() her zaman false döner, dolayısıyla
# mevcut oyun davranışı hiç değişmez.


## Bu kart silah sisteminin sorumluluğunda mı?
static func handles(card_id: StringName) -> bool:
	return WeaponCards.CARDS.has(card_id)


## Kart seçildiğinde çağrılır.
## game: main.gd düğümü — paddle, balls, build_hud buradan erişilir.
static func apply(game: Node, card_id: StringName, level: int) -> void:
	if not handles(card_id):
		return
	# CODEX: silahı rakete monte et / seviyesini güncelle.
	push_warning("WeaponSystem.apply henüz uygulanmadı: %s Lv%d" % [card_id, level])


## Run başında çağrılır; kalıcı silah durumunu sıfırlar.
static func reset_run(_game: Node) -> void:
	pass


## Her karede çağrılır; ateşleme zamanlayıcıları burada işlenir.
static func process(_game: Node, _delta: float) -> void:
	pass
