extends GdUnitTestSuite

## BELGELERDEKI SAYILAR HALA DOGRU MU?
##
## CLAUDE.md / AGENTS.md bolum 7 ve GOREVLER.md, iki ajanin ve
## kullanicinin karar verirken okudugu yerler. Oradaki her sayi bir
## olcumden geliyor ama kod degistikce sessizce bayatliyor.
##
## Gercek ornek: "havuz kapasitesi 52" yaziyordu. O sayi Codex'in silah
## turu birlesmeden ONCE olculmustu (5 silah). 8 silahla gercek deger 58
## oldu ve belge iki hafta yanlis kaldi. Bu test o tur sapmayi yakalar.
##
## Test kirilirsa: once kodun mu belgenin mi degistigine bak. Kod
## kasitli degistiyse belgeyi ve buradaki beklenen degeri guncelle.

const DOC_PATHS := ["res://CLAUDE.md", "res://AGENTS.md"]


func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	assert_object(f).override_failure_message("%s acilamadi" % path).is_not_null()
	var text := f.get_as_text()
	f.close()
	return text


func test_claude_ve_agents_ayni_icerikte() -> void:
	# Proje kurali: ikisi ayni olmali (yalnizca giris satiri sirasi farkli).
	var a := _read("res://CLAUDE.md").split("\n")
	var b := _read("res://AGENTS.md").split("\n")
	assert_int(a.size()).override_failure_message(
		"CLAUDE.md ve AGENTS.md satir sayisi farkli - biri guncellenmemis"
	).is_equal(b.size())
	var farkli := 0
	for i in range(a.size()):
		if a[i] != b[i]:
			farkli += 1
	assert_int(farkli).override_failure_message(
		"CLAUDE.md ve AGENTS.md %d satirda ayrisiyor (yalnizca 1 bekleniyor)" % farkli
	).is_less_equal(1)


func test_kart_havuzu_sayilari_belgeyle_ayni() -> void:
	var kart_sayisi := 0
	var kapasite := 0
	for yol: String in ["res://card_pool.gd", "res://weapons/weapon_cards.gd"]:
		var icerik := _read(yol)
		var regex := RegEx.new()
		regex.compile(r'"max_level":\s*(\d+)')
		for m in regex.search_all(icerik):
			kart_sayisi += 1
			kapasite += int(m.get_string(1))

	var belge := _read("res://CLAUDE.md")
	assert_bool(belge.contains("**%d kart**" % kart_sayisi)).override_failure_message(
		"Belgede yazan kart sayisi kodla uyusmuyor. Kodda %d kart var." % kart_sayisi
	).is_true()
	assert_bool(belge.contains("havuz kapasitesi %d" % kapasite)).override_failure_message(
		"Belgede yazan havuz kapasitesi kodla uyusmuyor. Kodda %d secim var." % kapasite
	).is_true()


func test_boss_derinlikleri_belgeyle_ayni() -> void:
	# Belge: "10 boss (depth 6, 12, 18, 24, 30, 36, 42, 48, 54, 60)"
	# Kod: POST_BOSS_DEPTH sabitleri, her biri boss derinliginin bir fazlasi.
	var main_gd := _read("res://main.gd")
	var regex := RegEx.new()
	regex.compile(r"POST_BOSS_DEPTH := (\d+)")
	var post_derinlikler: Array[int] = []
	for m in regex.search_all(main_gd):
		post_derinlikler.append(int(m.get_string(1)))

	assert_int(post_derinlikler.size()).override_failure_message(
		"Belge 10 boss diyor, kodda %d POST_BOSS_DEPTH var" % post_derinlikler.size()
	).is_equal(10)

	var belge := _read("res://CLAUDE.md")
	for post_depth: int in post_derinlikler:
		var boss_depth := post_depth - 1
		assert_bool(belge.contains(str(boss_depth))).override_failure_message(
			"Boss derinligi %d belgede gecmiyor" % boss_depth
		).is_true()


func test_ascension_inis_tabani_belgeyle_ayni() -> void:
	# Belge: "Ascension 10'un iniş tabanı (0.368s)"
	var gm = Engine.get_main_loop().root.get_node_or_null("GameManager")
	assert_object(gm).is_not_null()
	var onceki: int = gm.run_ascension
	gm.run_ascension = 10
	var taban: float = gm.get_ascension_min_step_interval(0.45)
	gm.run_ascension = onceki

	var belge := _read("res://CLAUDE.md")
	var yazilan := "%.3f" % taban
	assert_bool(belge.contains(yazilan)).override_failure_message(
		"Belge ascension 10 tabanini yanlis yaziyor. Kodda %s" % yazilan
	).is_true()
