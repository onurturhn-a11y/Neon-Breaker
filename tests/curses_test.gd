extends GdUnitTestSuite

## Faz 4.2 lanet sistemi: gonullu zorluk <-> odul carpani dengesi.
## Her lanet bir sey ALMALI ve karsiliginda bir sey VERMELI.


func test_dort_lanet_tanimli() -> void:
	assert_int(Curses.get_ids().size()).is_equal(4)


func test_her_lanetin_adi_aciklamasi_ve_odulu_var() -> void:
	for curse_id: StringName in Curses.get_ids():
		assert_str(Curses.get_curse_name(curse_id)).is_not_empty()
		assert_str(Curses.get_description(curse_id)).is_not_empty()
		assert_str(Curses.get_reward_text(curse_id)).is_not_empty()


func test_her_lanet_bir_bedel_ve_bir_odul_tasir() -> void:
	for curse_id: StringName in Curses.get_ids():
		var data := Curses.get_data(curse_id)
		# Odul: kazanc carpani mutlaka pozitif olmali.
		assert_float(float(data.get("gain_multiplier", 0.0))).is_greater(0.0)
		# Bedel: en az bir eksende oyuncunun aleyhine olmali.
		var descent: float = float(data.get("descent_scale", 1.0))
		var armor: float = float(data.get("armor_bonus", 0.0))
		var attacker: float = float(data.get("attacker_scale", 1.0))
		var life: int = int(data.get("life_cost", 0))
		var bedel_var := descent < 1.0 or armor > 0.0 or attacker < 1.0 or life > 0
		assert_bool(bedel_var).override_failure_message(
			"Lanet '%s' hicbir bedel tasimiyor - bedava odul" % curse_id
		).is_true()


func test_lanetler_birikimli_carpiliyor() -> void:
	var tek := {&"haste": true}
	var cift := {&"haste": true, &"armor": true}
	# Kazanc carpani birikmeli.
	assert_float(Curses.get_gain_multiplier(cift)).is_greater(
		Curses.get_gain_multiplier(tek)
	)
	# Bos sozluk notr olmali.
	assert_float(Curses.get_gain_multiplier({})).is_equal(1.0)
	assert_float(Curses.get_descent_scale({})).is_equal(1.0)
	assert_float(Curses.get_armor_bonus({})).is_equal(0.0)


func test_bilinmeyen_lanet_kimligi_cokmez() -> void:
	assert_float(Curses.get_gain_multiplier({&"olmayan_lanet": true})).is_equal(1.0)
	assert_str(Curses.get_curse_name(&"olmayan_lanet")).is_not_null()
