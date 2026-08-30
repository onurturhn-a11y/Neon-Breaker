extends GdUnitTestSuite

## Faz 5.2, 5.3, 6.1 ve 6.2'de duzeltilen dort gercek hatayi kilitler.
## Bunlarin hepsi sessizce geri alinabilir cinsten - test o yuzden var.

var gm: Node


func before_test() -> void:
	gm = Engine.get_main_loop().root.get_node_or_null("GameManager")
	assert_object(gm).override_failure_message(
		"GameManager autoload bulunamadi - test ortami yanlis"
	).is_not_null()


# ==================================================
# FAZ 6.1 — run'in ikinci yarisi ilerleme vermiyordu
# ==================================================

func test_derinlik_xp_carpani_derinlik_1de_notr() -> void:
	# Erken olen oyuncu etkilenmemeli.
	assert_float(gm.get_depth_xp_multiplier(1)).is_equal(1.0)


func test_derinlik_xp_carpani_derinlikle_artar() -> void:
	var previous: float = gm.get_depth_xp_multiplier(1)
	for depth in [8, 16, 32, 56]:
		var current: float = gm.get_depth_xp_multiplier(depth)
		assert_float(current).is_greater(previous)
		previous = current
	# Olculen deger: son bossta ~4.3x.
	assert_float(gm.get_depth_xp_multiplier(56)).is_equal_approx(4.30, 0.05)


func test_derinlik_xp_carpani_sifir_ve_negatife_dayanikli() -> void:
	assert_float(gm.get_depth_xp_multiplier(0)).is_equal(1.0)
	assert_float(gm.get_depth_xp_multiplier(-10)).is_equal(1.0)


# ==================================================
# FAZ 5.3 — ascension inis hizinda kozmetikti
# ==================================================

func test_ascension_inis_tabanini_da_indirir() -> void:
	# Sabit taban, ascension'i derinlik 9'dan sonra kozmetige ceviriyordu.
	var base := 0.45
	gm.run_ascension = 0
	var floor_asc0: float = gm.get_ascension_min_step_interval(base)
	gm.run_ascension = 10
	var floor_asc10: float = gm.get_ascension_min_step_interval(base)
	assert_float(floor_asc0).is_equal_approx(0.450, 0.001)
	assert_float(floor_asc10).is_less(floor_asc0)
	assert_float(floor_asc10).is_equal_approx(0.368, 0.005)
	gm.run_ascension = 0


func test_ascension_inis_carpani_da_siki_lasir() -> void:
	gm.run_ascension = 0
	var scale_0: float = gm.get_ascension_descent_scale()
	gm.run_ascension = 10
	var scale_10: float = gm.get_ascension_descent_scale()
	assert_float(scale_10).is_less(scale_0)
	gm.run_ascension = 0


# ==================================================
# FAZ 5.2 — bayat silah sayaci CORE agirligini bozuyordu
# ==================================================

func test_silah_sayaci_dolu_yuvalari_goruyor() -> void:
	gm.reset_weapon_slots()
	assert_int(gm.get_active_weapon_count()).is_equal(0)
	# Plazma DISI iki silah: eski sayac bunlari goremiyordu ve 0 donuyordu.
	gm.acquire_or_upgrade_weapon(&"RAILGUN")
	assert_int(gm.get_active_weapon_count()).is_equal(1)
	gm.acquire_or_upgrade_weapon(&"MORTAR")
	assert_int(gm.get_active_weapon_count()).is_equal(2)
	gm.reset_weapon_slots()


func test_plazma_cift_sayilmaz() -> void:
	# Plazma hem yuva silahi hem eski plasma_level alanina yaziyor.
	gm.reset_weapon_slots()
	gm.acquire_or_upgrade_weapon(&"PLASMA")
	assert_int(gm.get_active_weapon_count()).is_equal(1)
	gm.reset_weapon_slots()


# ==================================================
# FAZ 6.2 — ascension boss HP'sini artirip hasar tavanini artirmiyordu
# ==================================================

func test_ascension_hasar_tavanini_esiklerde_acar() -> void:
	var state_at = func(asc: int) -> Dictionary:
		gm.run_ascension = asc
		return CardSystem.make_state(gm, true, true)
	# asc 0-4: bonus yok
	assert_int(CardSystem.get_ascension_level_bonus(&"crit_hit", state_at.call(0))).is_equal(0)
	assert_int(CardSystem.get_ascension_level_bonus(&"crit_hit", state_at.call(4))).is_equal(0)
	# asc 5-9: +1
	assert_int(CardSystem.get_ascension_level_bonus(&"crit_hit", state_at.call(5))).is_equal(1)
	assert_int(CardSystem.get_ascension_level_bonus(&"crit_hit", state_at.call(9))).is_equal(1)
	# asc 10: +2, ve tavanda kalir
	assert_int(CardSystem.get_ascension_level_bonus(&"crit_hit", state_at.call(10))).is_equal(2)
	assert_int(CardSystem.get_ascension_level_bonus(&"crit_hit", state_at.call(99))).is_equal(2)
	gm.run_ascension = 0


func test_yalnizca_hasar_kartlari_etkilenir() -> void:
	gm.run_ascension = 10
	var state := CardSystem.make_state(gm, true, true)
	# Hasar kartlari acilir.
	for card_id in [&"crit_hit", &"extra_ball", &"ball_speed", &"pierce", &"fireball"]:
		assert_int(CardSystem.get_ascension_level_bonus(card_id, state)) \
			.override_failure_message("'%s' hasar karti, acilmali" % card_id).is_equal(2)
	# Yardimci kartlar ACILMAZ.
	for card_id in [&"paddle_width", &"revive", &"drop_rate", &"xp_gain"]:
		assert_int(CardSystem.get_ascension_level_bonus(card_id, state)) \
			.override_failure_message("'%s' hasar karti degil, acilmamali" % card_id).is_equal(0)
	gm.run_ascension = 0


## DIKKAT: CardSystem.make_state derinligi KOPYALIYOR ama ascension'i
## kopyalamiyor — gm referansini tutuyor ve run_ascension'i cagri aninda
## okuyor. Yani eski bir state, ascension degistikten sonra yeni degeri
## gorur. Bu testi ilk yazdigimda tam buna takildim: asc0 degerlerini
## ascension'i 10 yaptiktan SONRA okumustum, ikisi de 10 gordu.
##
## Oyunda ascension run ortasinda degismedigi icin bu zararsiz, ama
## test yazarken tuzak. Tum asc0 degerleri once okunur.
func test_hasar_tavani_ascension_ile_gercekten_yukselir() -> void:
	gm.run_ascension = 0
	var state_0 := CardSystem.make_state(gm, true, true)
	var crit_0: int = CardSystem.get_card_level_cap(&"crit_hit", state_0)
	var pierce_0: int = CardSystem.get_card_level_cap(&"pierce", state_0)

	gm.run_ascension = 10
	var state_10 := CardSystem.make_state(gm, true, true)
	var crit_10: int = CardSystem.get_card_level_cap(&"crit_hit", state_10)
	var pierce_10: int = CardSystem.get_card_level_cap(&"pierce", state_10)

	assert_int(crit_10).is_greater(crit_0)
	# pierce WEAPON_CARDS'ta da: boss milestone tavani bonusu YUTMAMALI.
	assert_int(pierce_10).override_failure_message(
		"pierce tavani ascension ile acilmadi - boss milestone tavani bonusu yutuyor"
	).is_greater(pierce_0)
	gm.run_ascension = 0
