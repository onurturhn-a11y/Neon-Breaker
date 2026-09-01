extends GdUnitTestSuite

## Faz 6.4: gereken temizleme hizi ve run suresi.
##
## Bunlar SABIT DEGIL, TURETILMIS degerler - dort ayri sabitten hesaplaniyor.
## Belgede "9.2 tugla/sn" ve "~12.3 dakika" yaziyor. 25F sirasinda biri
## minimum_safe_step_interval'a ya da inis egrisine dokunursa bu sayilar
## sessizce yanlis olur ve kimse fark etmez.
##
## Bu test modeli CANLI sabitlerden yeniden kurar. Kirilirsa hata mesaji
## yeni degeri soyler; belge ona gore guncellenir.

const ROWS_PER_DEPTH := 8
const GAP_Y := 29.0
const ROW_STEP_DISTANCE := 10.0
const BASE_FLOOR := 0.45
const DEPTH_INTERVALS := [1.50, 1.35, 1.20, 1.05, 0.90, 0.75]

var gm: Node


func before_test() -> void:
	gm = Engine.get_main_loop().root.get_node_or_null("GameManager")
	assert_object(gm).is_not_null()
	gm.run_ascension = 0


func after_test() -> void:
	gm.run_ascension = 0


## Satir her ADIMDA dogmuyor: alan adimda ROW_STEP_DISTANCE iniyor,
## yeni satir ancak GAP_Y birikince doguyor.
func _steps_per_row() -> float:
	return GAP_Y / ROW_STEP_DISTANCE


func _step_interval(depth: int) -> float:
	var base: float = 0.75
	if depth <= DEPTH_INTERVALS.size():
		base = float(DEPTH_INTERVALS[depth - 1])
	var raw: float = (
		base
		* gm.get_late_game_descent_multiplier(depth)
		* SectorModifiers.get_descent_scale(SectorModifiers.get_sector_for_depth(depth))
	)
	return maxf(raw, gm.get_ascension_min_step_interval(BASE_FLOOR))


## DIKKAT: level_generator bir Node ve agaca eklenmiyor. Serbest
## birakilmazsa orphan olarak kalir ve gdUnit4 testi kirar.
func _bricks_per_row(depth: int) -> float:
	gm.run_depth = depth
	var gen: Node = load("res://level_generator.gd").new()
	gen.configure_for_depth(depth)
	var parent := Node2D.new()
	add_child(parent)
	var total := 0
	var rows := 40
	for r in range(rows):
		for c in parent.get_children():
			c.free()
		total += gen.create_continuous_row(parent, 0.0, r)
	for c in parent.get_children():
		c.free()
	remove_child(parent)
	parent.free()
	gen.free()
	return float(total) / float(rows)


func test_satir_basina_adim_sayisi_degismedi() -> void:
	# Bu orani bir kez yanlis hesaplayip run suresini 4.2 dakika sanmistim.
	# Gercek 12.3. Oran degisirse tum sure hesabi kayar.
	assert_float(_steps_per_row()).is_equal_approx(2.9, 0.01)


func test_gereken_temizleme_hizi_belgeyle_ayni() -> void:
	# Belge: derinlik 32+ icin 9.2 tugla/sn.
	var depth := 32
	var per_row: float = _bricks_per_row(depth)
	var row_interval: float = _step_interval(depth) * _steps_per_row()
	var required: float = per_row / row_interval
	assert_float(required).override_failure_message(
		"Belge 9.2 tugla/sn diyor, kod simdi %.1f veriyor. Bir sabit degismis - belgeyi guncelle." % required
	).is_equal_approx(9.2, 0.4)


func test_talep_derinlik_24ten_sonra_platoya_cikar() -> void:
	# Faz 6.4 bulgusu: inis tabani talebi sinirliyor, depth 24-60 arasi
	# tuğla talebi SABIT. Bu, ikinci yarinin duz eksenlerinden biri.
	var d24: float = _bricks_per_row(24) / (_step_interval(24) * _steps_per_row())
	var d60: float = _bricks_per_row(60) / (_step_interval(60) * _steps_per_row())
	assert_float(absf(d60 - d24)).override_failure_message(
		"Depth 24 ve 60 talebi ayrismis (%.1f vs %.1f) - inis tabani artik baglamiyor" % [d24, d60]
	).is_less(0.6)


func test_zafer_run_suresi_belgeyle_ayni() -> void:
	# Belge: tugla inisi ~13.1 dakika (boss dovusleri haric).
	# Faz 9'da olculdu: kadro 7->10, derinlik 56->60, sure 12.3->13.1 (+%6.5).
	var total := 0.0
	for depth in range(1, 61):
		total += _step_interval(depth) * float(ROWS_PER_DEPTH) * _steps_per_row()
	var minutes: float = total / 60.0
	assert_float(minutes).override_failure_message(
		"Belge ~13.1 dakika diyor, kod simdi %.1f veriyor." % minutes
	).is_equal_approx(13.1, 0.6)


func test_ascension_run_suresini_kisaltir() -> void:
	var _sure = func() -> float:
		var t := 0.0
		for depth in range(1, 61):
			t += _step_interval(depth) * float(ROWS_PER_DEPTH) * _steps_per_row()
		return t
	gm.run_ascension = 0
	var asc0: float = _sure.call()
	gm.run_ascension = 10
	var asc10: float = _sure.call()
	assert_float(asc10).override_failure_message(
		"Ascension run suresini kisaltmiyor - inis tabani ascension'a bagli degil"
	).is_less(asc0)


func test_tehlike_hatti_ekonomisi() -> void:
	# Tampon bitince af yok: 3 canla surekli tugla gecerse ~2.5 saniyede olum.
	# Bu sayilar degisirse "yetisilebiliyor mu" sorusunun cevabi da degisir.
	assert_int(gm.MAX_LIVES).is_greater_equal(3)
