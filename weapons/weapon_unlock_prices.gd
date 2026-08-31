extends RefCounted
# Account access prices; never run weapon levels or equipped slots.
const PRICES := {
	&"plasma": [0, 100, 250],
	&"arc_cannon": [150, 250, 450],
	&"scatter_cannon": [200, 300, 500],
	&"railgun": [350, 550, 900],
	&"homing_missile": [300, 450, 750],
	&"pulse_laser": [400, 650, 1050],
	&"mortar": [250, 400, 650],
	&"drone_bay": [600, 900, 1400],
	&"orbital_marker": [800, 1200, 1800],
}
const TITLES := {
	&"plasma": "PLAZMA SİLAHI", &"arc_cannon": "ZİNCİR ŞİMŞEK",
	&"scatter_cannon": "SAÇMA TOPU", &"railgun": "RAY SİLAHI",
	&"homing_missile": "AVCI FÜZELER", &"pulse_laser": "DARBE IŞINI",
	&"mortar": "HAVAN TOPU", &"drone_bay": "SALDIRI DRONLARI",
	&"orbital_marker": "YÖRÜNGE SALDIRISI",
}
static func get_price(card_id: StringName, level: int) -> int:
	if not PRICES.has(card_id) or level < 1 or level > 3:
		return -1
	return int(PRICES[card_id][level - 1])

