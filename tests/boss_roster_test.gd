extends GdUnitTestSuite

## Boss kadrosu butun mu?
##
## Bir bossu oyuna baglamak main.gd'de BES ayri yere dokunmayi gerektiriyor:
## derinlik sabiti, yenilgi bayragi, on_continuous_row_spawned dali,
## _on_boss_defeated dali, _get_boss_scene kolu. Faz 9'da kadro 7'den 10'a
## cikarken bunlarin herhangi biri unutulsaydi boss ya hic gelmez ya da
## gelip run'i kilitlerdi - ikisi de sessizce.
##
## Bu test main.gd'yi metin olarak okuyup bes listenin de ayni bossları
## icerdigini dogruluyor.

const MAIN := "res://main.gd"

## Kadro, derinlik sirasiyla. Yeni boss eklerken BURAYA da yaz.
const ROSTER := [
	["core", 6], ["sentinel", 12], ["harvester", 18], ["celestial", 24],
	["void", 30], ["chorus", 36], ["sovereign", 42], ["architect", 48],
	["inversion", 54], ["chronoform", 60],
]


func _read_main() -> String:
	var f := FileAccess.open(MAIN, FileAccess.READ)
	assert_object(f).is_not_null()
	var text := f.get_as_text()
	f.close()
	return text


func _ints(pattern: String, text: String) -> Array[int]:
	var regex := RegEx.new()
	regex.compile(pattern)
	var out: Array[int] = []
	for m in regex.search_all(text):
		out.append(int(m.get_string(1)))
	return out


func test_derinlik_sabitleri_kadroyla_ayni() -> void:
	var text := _read_main()
	var milestones := _ints(r"BOSS_MILESTONE_DEPTH := (\d+)", text)
	milestones.sort()
	var beklenen: Array[int] = []
	for entry: Array in ROSTER:
		beklenen.append(int(entry[1]))
	assert_array(milestones).override_failure_message(
		"Derinlik sabitleri kadroyla uyusmuyor. Kodda: %s" % str(milestones)
	).is_equal(beklenen)


func test_post_derinlik_her_zaman_bir_fazla() -> void:
	var text := _read_main()
	var milestones := _ints(r"BOSS_MILESTONE_DEPTH := (\d+)", text)
	var posts := _ints(r"POST_BOSS_DEPTH := (\d+)", text)
	assert_int(posts.size()).is_equal(milestones.size())
	milestones.sort()
	posts.sort()
	for i in range(milestones.size()):
		assert_int(posts[i]).override_failure_message(
			"POST derinligi %d, boss derinligi %d - bir fazla olmali" % [posts[i], milestones[i]]
		).is_equal(milestones[i] + 1)


func test_aralik_esit() -> void:
	var milestones := _ints(r"BOSS_MILESTONE_DEPTH := (\d+)", _read_main())
	milestones.sort()
	for i in range(1, milestones.size()):
		assert_int(milestones[i] - milestones[i - 1]).override_failure_message(
			"Boss araligi duzensiz: %d -> %d" % [milestones[i - 1], milestones[i]]
		).is_equal(6)


## Asil koruma: bes listenin de ayni bossları icermesi.
func test_her_boss_bes_yerde_de_var() -> void:
	var text := _read_main()
	for entry: Array in ROSTER:
		var boss: String = entry[0]
		assert_bool(text.contains('pending_boss_type = &"%s"' % boss)).override_failure_message(
			"'%s' on_continuous_row_spawned'da yok - bu boss hic gelmez." % boss
		).is_true()
		assert_bool(text.contains('defeated_boss_type == &"%s"' % boss)).override_failure_message(
			"'%s' _on_boss_defeated'de yok - yenilince run kilitlenir." % boss
		).is_true()
		assert_bool(text.contains('&"%s":' % boss)).override_failure_message(
			"'%s' _get_boss_scene'de yok - sahnesi yuklenemez." % boss
		).is_true()


func test_odul_index_i_her_boss_icin_ayri() -> void:
	var text := _read_main()
	var block := text.substr(text.find("func _get_boss_reward_index"))
	block = block.substr(0, block.find("func _award_boss_defeat_rewards"))
	var indices: Array[int] = _ints(r"return (\d+)", block)
	indices.sort()
	# core hicbir kola girmiyor, sondaki `return 0` onun. Kalan dokuz boss 1..9.
	assert_array(indices).override_failure_message(
		"Odul index'leri benzersiz 0..9 olmali, kodda: %s" % str(indices)
	).is_equal([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])


## Codex'in basarim sistemi bossları kendi listesinden taniyor. Kadro
## buyudugunde o liste guncellenmezse yeni bosslar record_boss_defeated()
## icinde sessizce elenir - hicbir hata vermez, yalnizca sayaclar eksik
## kalir. Faz 9'da tam bu oldu ve burada yakalandi.
func test_basarim_listesi_kadroyu_kapsiyor() -> void:
	var gm: Node = Engine.get_main_loop().root.get_node_or_null("GameManager")
	assert_object(gm).is_not_null()
	var ids: Array = gm.ACHIEVEMENT_BOSS_IDS
	for entry: Array in ROSTER:
		var boss: String = entry[0]
		assert_bool(ids.has(StringName(boss))).override_failure_message(
			"'%s' ACHIEVEMENT_BOSS_IDS'te yok - basarim sayaclarinda gorunmez." % boss
		).is_true()
	assert_int(ids.size()).override_failure_message(
		"Basarim listesinde kadroda olmayan id var: %s" % str(ids)
	).is_equal(ROSTER.size())
