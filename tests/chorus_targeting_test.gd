extends GdUnitTestSuite

## THE CHORUS: vurus hangi uyeye yaziliyor?
##
## Bu testin sebebi gercek bir hata: Chorus ilk yazildiginda tek buyuk
## carpisma kutusu (340x220) kullaniyordu ve vurusu uye merkezlerine
## 46 piksel yaricapla esliyordu. Top kutunun YUZEYINE carpiyor,
## collision.get_position() temas noktasini kutu kenarinda veriyor -
## o nokta cogu acida hicbir uyeye 46 piksel kadar yakin dusmuyordu.
## Sonuc: vuruslarin cogu "miss" donuyor, boss hasar almiyor ve
## oyuncuya hicbir geri bildirim gitmiyordu. Ekranda tamamen olu.
##
## Duzeltme: her uyenin kendi CollisionShape2D'si var, yaricap kapisi
## kaldirildi. Temas zaten uyenin sekliyle olustugu icin en yakin uye
## dogru uyedir.
##
## Test kirilirsa: birisi ya uye sekillerini kaldirmis ya da yaricap
## kapisini geri getirmistir. Ikisi de bossu tekrar vurulamaz yapar.

const CHORUS_SCENE := preload("res://boss_chorus.tscn")

var boss: Node2D


func before_test() -> void:
	boss = CHORUS_SCENE.instantiate()
	add_child(boss)
	await await_idle_frame()


func after_test() -> void:
	if is_instance_valid(boss):
		boss.queue_free()


func test_her_uyenin_kendi_carpisma_sekli_var() -> void:
	var shapes := 0
	for child in boss.get_children():
		if child is CollisionShape2D:
			shapes += 1
	# 5 uye sekli + taban sinifin duet govdesi
	assert_int(shapes).is_equal(boss.VOICE_COUNT + 1)


func test_uye_hpleri_toplami_boss_hpsine_esit() -> void:
	var total := 0
	for v: Dictionary in boss.voices:
		total += int(v.get("hp", 0))
	assert_int(total).is_equal(boss.VOICE_COUNT * boss.VOICE_HP)


## Asil koruma: halkadaki her uyenin uzerine yapilan vurus O uyeye yazilmali.
func test_her_uyenin_uzerindeki_vurus_o_uyeye_yazilir() -> void:
	for v: Dictionary in boss.voices:
		var holder: Node2D = v.get("node")
		assert_object(holder).is_not_null()
		var world := boss.to_global(holder.position)
		var region: StringName = boss._region_from_global_hit(world)
		assert_str(String(region)).is_equal("voice_%d" % int(v.get("index", -1)))


## Eski hatanin ta kendisi: kutu kenarindan gelen vurus da bir uyeye
## yazilmali, "miss" DONMEMELI. Carpisma artik yalniz uye sekilleriyle
## olustugu icin en yakin uye her zaman dogru cevaptir.
func test_kutu_kenarindan_gelen_vurus_miss_donmez() -> void:
	var edge_points: Array[Vector2] = [
		Vector2(0.0, 110.0), Vector2(100.0, 110.0), Vector2(-100.0, 110.0),
		Vector2(170.0, 0.0), Vector2(-170.0, 0.0), Vector2(0.0, -110.0),
	]
	for local: Vector2 in edge_points:
		var region: StringName = boss._region_from_global_hit(boss.to_global(local))
		assert_str(String(region)).override_failure_message(
			"Kutu kenarindaki %s vurusu miss dondu - eski hata geri gelmis." % local
		).starts_with("voice_")


func test_olu_uye_hedef_alinmaz() -> void:
	var first: Dictionary = boss.voices[0]
	first["hp"] = 0
	var world := boss.to_global((first.get("node") as Node2D).position)
	var region: StringName = boss._region_from_global_hit(world)
	assert_str(String(region)).is_not_equal("voice_%d" % int(first.get("index", -1)))
