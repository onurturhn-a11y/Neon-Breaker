extends GdUnitTestSuite

## Faz 7.3: koloni bina etkilerinde tek kaynak.
##
## Ayni diziler UC YERE kopyalanmisti (colony.gd UI metni, ball.gd,
## main.gd) ve birbirinden sapmislardi:
##   Ates Reaktoru sv3    -> UI "3 ek tugla" diyordu, oyun 4 veriyordu
##   Delici Arastirma sv2 -> UI "3 ek tugla" diyordu, oyun 2 veriyordu
##
## Diziler GameManager'a tasindi. Bu test kopyalarin geri gelmesini ve
## UI ile oyunun tekrar ayrismasini engeller.

var gm: Node


func before_test() -> void:
	gm = Engine.get_main_loop().root.get_node_or_null("GameManager")
	assert_object(gm).is_not_null()


func test_seviye_dizileri_dort_elemanli() -> void:
	# Indeks = seviye (0 = kurulmamis, 3 = maksimum).
	for dizi in [
		gm.PIERCING_RESEARCH_BASE_PENETRATION,
		gm.FIRE_REACTOR_BASE_EXTRA_TARGETS,
		gm.TECH_CENTER_MAGNET_MULTIPLIERS,
		gm.TECH_CENTER_FULL_LIFE_HEART_SALVAGE,
	]:
		assert_int(dizi.size()).is_equal(4)


func test_kurulmamis_bina_bonus_vermez() -> void:
	# Seviye 0 = bina yok. Hicbir eksende bedava bonus olmamali.
	assert_int(int(gm.PIERCING_RESEARCH_BASE_PENETRATION[0])).is_equal(0)
	assert_int(int(gm.FIRE_REACTOR_BASE_EXTRA_TARGETS[0])).is_equal(0)
	assert_float(float(gm.TECH_CENTER_MAGNET_MULTIPLIERS[0])).is_equal(1.0)
	assert_int(int(gm.TECH_CENTER_FULL_LIFE_HEART_SALVAGE[0])).is_equal(0)


func test_seviye_arttikca_bonus_azalmaz() -> void:
	for dizi in [
		gm.PIERCING_RESEARCH_BASE_PENETRATION,
		gm.FIRE_REACTOR_BASE_EXTRA_TARGETS,
		gm.TECH_CENTER_MAGNET_MULTIPLIERS,
		gm.TECH_CENTER_FULL_LIFE_HEART_SALVAGE,
	]:
		for i in range(1, dizi.size()):
			assert_float(float(dizi[i])).override_failure_message(
				"seviye %d, seviye %d'den dusuk - yukseltme geri gidiyor" % [i, i - 1]
			).is_greater_equal(float(dizi[i - 1]))


func test_maksimum_seviye_gercek_bonus_verir() -> void:
	# Lv3'e 65-136 PARCA odeniyor; karsiliginda bir sey gelmeli.
	assert_int(int(gm.PIERCING_RESEARCH_BASE_PENETRATION[3])).is_greater(0)
	assert_int(int(gm.FIRE_REACTOR_BASE_EXTRA_TARGETS[3])).is_greater(0)
	assert_float(float(gm.TECH_CENTER_MAGNET_MULTIPLIERS[3])).is_greater(1.0)
	assert_int(int(gm.TECH_CENTER_FULL_LIFE_HEART_SALVAGE[3])).is_greater(0)


func test_afinite_carpani_raket_kimligini_odullendirir() -> void:
	# UI metni "Delici Raketi ile" diyor; afinite carpani gercekten uygulanmali.
	gm.paddle_affinity = gm.PADDLE_NEUTRAL
	assert_float(gm.get_affinity_scale(gm.PADDLE_PIERCING)).is_equal(1.0)
	gm.paddle_affinity = gm.PADDLE_PIERCING
	assert_float(gm.get_affinity_scale(gm.PADDLE_PIERCING)).is_greater(1.0)
	gm.paddle_affinity = gm.PADDLE_NEUTRAL


func test_kopyalanan_diziler_colony_gdye_geri_donmemis() -> void:
	# Faz 7.3'te colony.gd'den kaldirilan kopyalar. Geri gelirlerse
	# UI ile oyun yeniden ayrisir.
	var dosya := FileAccess.open("res://colony.gd", FileAccess.READ)
	assert_object(dosya).is_not_null()
	var icerik := dosya.get_as_text()
	dosya.close()
	for kopya: String in [
		"const FIRE_REACTOR_EXTRA_BRICKS",
		"const PIERCING_RESEARCH_EXTRA_BRICKS",
		"const TECH_CENTER_MAGNET_BONUS_PERCENT",
		"const TECH_CENTER_FULL_HEART_SALVAGE",
	]:
		assert_bool(icerik.contains(kopya)).override_failure_message(
			"colony.gd'de '%s' geri gelmis - UI ile oyun yeniden ayrisabilir" % kopya
		).is_false()
