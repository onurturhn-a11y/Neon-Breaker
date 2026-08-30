extends GdUnitTestSuite

## Faz 7.1: ZINCIR BELLEGI karti hasara etki etmiyordu.
##
## Kombo sistemi iki yariya bolunmus: combo_manager.gd (gorsel - rank
## yazisi, ekran sarsintisi) ve chain_lightning_manager.gd (mekanik -
## hasar veren zincir). Esikleri birebir ayni, taban sureleri de ayni.
## Ama kart carpanini YALNIZCA gorsel yari uyguluyordu.
##
## Kart "Combo zinciri %75 daha uzun surer" diyor; oyuncu bunu zincir
## simseginin uzamasi diye okur. Bir secim harcayip ekrandaki yazinin
## uzun kalmasini aliyordu. Bu test o baglantinin tekrar kopmasini
## engeller.

var gm: Node
var clm: Node


func before_test() -> void:
	gm = Engine.get_main_loop().root.get_node_or_null("GameManager")
	assert_object(gm).is_not_null()
	clm = load("res://chain_lightning_manager.gd").new()
	add_child(clm)


func after_test() -> void:
	gm.set_card_level(&"combo_window", 0)
	if is_instance_valid(clm):
		clm.queue_free()


func test_kart_yokken_taban_sure_gecerli() -> void:
	gm.set_card_level(&"combo_window", 0)
	assert_float(gm.get_combo_timeout_multiplier()).is_equal(1.0)
	assert_float(clm._get_charge_timeout()).is_equal_approx(
		clm.LEGACY_CHARGE_TIMEOUT, 0.001
	)


func test_kart_zincir_simsegini_de_uzatir() -> void:
	# Asil duzeltme bu: kart yalnizca gorseli degil, hasari da etkilemeli.
	gm.set_card_level(&"combo_window", 0)
	var taban: float = clm._get_charge_timeout()
	for level in [1, 2, 3]:
		gm.set_card_level(&"combo_window", level)
		assert_float(clm._get_charge_timeout()).override_failure_message(
			"combo_window Lv%d zincir simsegi penceresini uzatmadi" % level
		).is_greater(taban)


func test_gorsel_ve_mekanik_yari_ayni_sureyi_kullanir() -> void:
	# Ikisi tek sistemin iki yarisi; sureleri ayrisirsa kart yine yalan soyler.
	for level in [0, 1, 2, 3]:
		gm.set_card_level(&"combo_window", level)
		var gorsel: float = 0.85 * gm.get_combo_timeout_multiplier()
		var mekanik: float = clm._get_charge_timeout()
		assert_float(mekanik).override_failure_message(
			"Lv%d: gorsel %.4f, mekanik %.4f - ayrismislar" % [level, gorsel, mekanik]
		).is_equal_approx(gorsel, 0.0001)


func test_kart_vaadi_sayilarla_tutuyor() -> void:
	# Kart metni: %5 / %10 / %15 daha uzun (kart dengesi turunde dusuruldu).
	var beklenen := {1: 1.05, 2: 1.10, 3: 1.15}
	for level: int in beklenen.keys():
		gm.set_card_level(&"combo_window", level)
		assert_float(gm.get_combo_timeout_multiplier()).override_failure_message(
			"combo_window Lv%d karti %%%d vaat ediyor ama carpan tutmuyor"
				% [level, int((float(beklenen[level]) - 1.0) * 100.0)]
		).is_equal_approx(float(beklenen[level]), 0.001)


func test_esikler_iki_yaride_de_ayni() -> void:
	# combo_manager.THRESHOLDS ile CHARGE_THRESHOLDS ayrisirsa rank'ler kayar.
	var combo_thresholds := [3, 6, 9, 12, 15, 18, 21, 24, 27]
	assert_array(clm.CHARGE_THRESHOLDS).override_failure_message(
		"Zincir simsegi esikleri kombo esiklerinden ayrildi"
	).is_equal(combo_thresholds)
