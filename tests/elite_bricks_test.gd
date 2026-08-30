extends GdUnitTestSuite

## Faz 5.1'de olculen elit tugla kalibrasyonunu kilitler.
##
## Bu sayilar tahminle degil olcumle secildi. Ilk denemede oran tugla
## basinaydi ve satir boyunca birikiyordu: derinlik 25'te satirlarin
## %81'i elitli cikiyordu, yani elit "olay" degil norm oluyordu.
## Satir bazli yeniden kalibre edildi. Bu test o kalibrasyonun sessizce
## bozulmasini engeller.


func test_derinlik_4_oncesi_elit_cikmaz() -> void:
	for depth in [1, 2, 3]:
		assert_float(EliteBricks.get_chance(depth, 0)).is_equal(0.0)
		assert_bool(EliteBricks.is_active_at_depth(depth)).is_false()


func test_derinlik_4te_baslar() -> void:
	assert_bool(EliteBricks.is_active_at_depth(4)).is_true()
	assert_float(EliteBricks.get_chance(4, 0)).is_equal_approx(0.010, 0.0001)


func test_oran_derinlikle_artar_ve_tavana_vurur() -> void:
	var previous := EliteBricks.get_chance(4, 0)
	for depth in range(5, 21):
		var current := EliteBricks.get_chance(depth, 0)
		assert_float(current).is_greater_equal(previous)
		previous = current
	# Derinlik 20'de tavan.
	assert_float(EliteBricks.get_chance(20, 0)).is_equal_approx(0.045, 0.0001)
	# Sonrasi sabit kalir.
	assert_float(EliteBricks.get_chance(56, 0)).is_equal_approx(0.045, 0.0001)


func test_ascension_orani_artirir_ama_mutlak_tavan_asilmaz() -> void:
	assert_float(EliteBricks.get_chance(20, 10)).is_greater(EliteBricks.get_chance(20, 0))
	for depth in [4, 20, 56]:
		for ascension in [0, 5, 10, 99]:
			assert_float(EliteBricks.get_chance(depth, ascension)) \
				.is_less_equal(EliteBricks.ABSOLUTE_MAX_CHANCE)


func test_can_derinlikle_basamakli_artar() -> void:
	assert_int(EliteBricks.get_health(4)).is_equal(3)
	assert_int(EliteBricks.get_health(11)).is_equal(3)
	assert_int(EliteBricks.get_health(12)).is_equal(4)
	assert_int(EliteBricks.get_health(19)).is_equal(4)
	assert_int(EliteBricks.get_health(20)).is_equal(5)
	# Elit her zaman zirhliyi (2 can) gecmeli.
	for depth in [4, 12, 20, 56]:
		assert_int(EliteBricks.get_health(depth)).is_greater(2)


func test_satir_basina_en_fazla_bir_elit() -> void:
	# Dort elitli satir oynanabilir degil; sinir 1 olmali.
	assert_int(EliteBricks.MAX_PER_ROW).is_equal(1)


func test_dusurme_carpani_odul_veriyor() -> void:
	# Yuksek can karsiliginda degerli dusurme sarti.
	assert_float(EliteBricks.DROP_MULTIPLIER).is_greater(1.0)
