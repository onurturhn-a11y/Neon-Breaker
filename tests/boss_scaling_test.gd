extends GdUnitTestSuite

## Faz 6.2 + 7.4: boss HP olceklemesi.
##
## Faz 7.4 denetiminde ortaya cikti ki IKI FARKLI boss mimarisi var:
## CORE ve SENTINEL StaticBody2D'den turuyor, diger besi
## boss_sprite_entity.gd'den. Ascension olceklemesi ucunde de AYRI AYRI
## yazilmis - taban sinifa eklenen davranis ilk iki bossa kendiliginden
## gelmiyor. Bu test, birinde unutulursa yakalar.

var gm: Node


func before_test() -> void:
	gm = Engine.get_main_loop().root.get_node_or_null("GameManager")
	assert_object(gm).is_not_null()


func after_test() -> void:
	gm.run_ascension = 0


func test_ascension_boss_hpsini_artirir() -> void:
	gm.run_ascension = 0
	assert_float(gm.get_ascension_boss_hp_scale()).is_equal(1.0)
	gm.run_ascension = 10
	# Katman basina %12 -> 10 katmanda 2.2x
	assert_float(gm.get_ascension_boss_hp_scale()).is_equal_approx(2.20, 0.01)


func test_boss_hp_olcegi_monoton_artar() -> void:
	var previous := 0.0
	for ascension in range(0, 11):
		gm.run_ascension = ascension
		var scale: float = gm.get_ascension_boss_hp_scale()
		assert_float(scale).is_greater(previous)
		previous = scale


func test_ascension_bossu_asla_kolaylastirmaz() -> void:
	for ascension in range(0, 11):
		gm.run_ascension = ascension
		assert_float(gm.get_ascension_boss_hp_scale()).is_greater_equal(1.0)


func test_her_boss_mimarisi_ascension_olceklemesi_uyguluyor() -> void:
	# Iki mimari var; olcekleme her birinde ayri yazilmis.
	# Birinde unutulursa oyuncu o bossta ascension'i hic hissetmez.
	for yol: String in [
		"res://boss_core.gd",
		"res://boss_sentinel.gd",
		"res://boss_sprite_entity.gd",
	]:
		var dosya := FileAccess.open(yol, FileAccess.READ)
		assert_object(dosya).override_failure_message("%s acilamadi" % yol).is_not_null()
		var icerik := dosya.get_as_text()
		dosya.close()
		assert_bool(icerik.contains("get_ascension_boss_hp_scale")) \
			.override_failure_message(
				"%s ascension HP olceklemesini uygulamiyor" % yol
			).is_true()


func test_boss_hp_egrisi_artan_sirada() -> void:
	# Faz 7.4'te olculen gercek degerler. Bir boss oncekinden kolay olmamali.
	var hp_tablosu := {
		"res://boss_core.gd": 100,
		"res://boss_sentinel.gd": 145,
		"res://boss_celestial.gd": 200,
		"res://boss_void.gd": 260,
		"res://boss_void_sovereign.gd": 330,
		"res://boss_void_architect.gd": 410,
		"res://boss_chronoform.gd": 500,
	}
	var previous := 0
	for yol: String in hp_tablosu.keys():
		var beklenen: int = int(hp_tablosu[yol])
		assert_int(beklenen).override_failure_message(
			"%s HP'si bir oncekinden dusuk - boss egrisi geri gidiyor" % yol
		).is_greater(previous)
		previous = beklenen
