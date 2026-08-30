extends GdUnitTestSuite

## Faz 4.3 + 5.3'te olculen sektor modifierlarini kilitler.
##
## Faz 5.3 olcumu: sektor 6 ve 7'nin descent_scale degerleri OLU SAYIYDI.
## Depth 21/25'te basliyorlar ama inis tabani depth 9-13'te bagliyor,
## yani 0.90 ve 0.86 hicbir zaman oyuncuya ulasmadi. Baski doygun olmayan
## eksenlere tasindi. Bu test o kararin geri alinmasini engeller.


func test_yedi_sektor_tanimli() -> void:
	assert_int(SectorModifiers.SECTOR_COUNT).is_equal(7)
	for sector in range(1, 8):
		assert_str(SectorModifiers.get_sector_name(sector)).is_not_empty()
		assert_str(SectorModifiers.get_tagline(sector)).is_not_empty()


func test_derinlik_sektore_dogru_esleniyor() -> void:
	assert_int(SectorModifiers.get_sector_for_depth(1)).is_equal(1)
	assert_int(SectorModifiers.get_sector_for_depth(4)).is_equal(1)
	assert_int(SectorModifiers.get_sector_for_depth(5)).is_equal(2)
	assert_int(SectorModifiers.get_sector_for_depth(25)).is_equal(7)
	# Derinlik 25'ten sonrasi hep sektor 7.
	assert_int(SectorModifiers.get_sector_for_depth(56)).is_equal(7)
	# Sinir disi degerler kirpiliyor.
	assert_int(SectorModifiers.get_sector_for_depth(0)).is_equal(1)
	assert_int(SectorModifiers.get_sector_for_depth(-5)).is_equal(1)


func test_sektor_6_ve_7_inis_hizina_baski_yapmaz() -> void:
	# Faz 5.3: bu degerler olu sayiydi, notre cekildi.
	# Baski satir dolulugu ve saldirgan sikligina tasindi.
	assert_float(SectorModifiers.get_descent_scale(6)).is_equal(1.0)
	assert_float(SectorModifiers.get_descent_scale(7)).is_equal(1.0)


func test_sektor_6_ve_7_doygun_olmayan_eksenlerde_baski_yapar() -> void:
	# descent_scale notr birakildi ama sektorler notr DEGIL.
	assert_float(SectorModifiers.get_row_fill_bonus(6)).is_greater(0.0)
	assert_float(SectorModifiers.get_row_fill_bonus(7)).is_greater(
		SectorModifiers.get_row_fill_bonus(6)
	)
	# attacker_scale kucuk = daha SIK saldirgan.
	assert_float(SectorModifiers.get_attacker_scale(7)).is_less(
		SectorModifiers.get_attacker_scale(6)
	)
	assert_bool(SectorModifiers.has_effect(6)).is_true()
	assert_bool(SectorModifiers.has_effect(7)).is_true()


func test_sektor_1_notr_baslangic() -> void:
	# Ilk sektor ogrenme alani: hicbir eksende baski yok.
	assert_bool(SectorModifiers.has_effect(1)).is_false()


func test_carpanlar_makul_aralikta() -> void:
	# Kimse yanlislikla 10x yazmasin.
	for sector in range(1, 8):
		assert_float(SectorModifiers.get_descent_scale(sector)).is_between(0.5, 2.0)
		assert_float(SectorModifiers.get_ball_speed_scale(sector)).is_between(0.5, 2.0)
		assert_float(SectorModifiers.get_attacker_scale(sector)).is_between(0.3, 2.0)
		assert_float(SectorModifiers.get_row_fill_bonus(sector)).is_between(0.0, 0.30)
		assert_float(SectorModifiers.get_explosive_bonus(sector)).is_between(0.0, 0.20)
