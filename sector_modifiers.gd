extends RefCounted
class_name SectorModifiers

# ==================================================
# SEKTÖR MODİFİER'LARI
# ==================================================
# Yedi sektör eskiden yalnızca arka plan rengini değiştiriyordu. Artık her
# sektörün oynanışa dokunan bir imzası var.
#
# Modifier'lar SAF veridir; etkileri okuyan taraf uygular:
#   continuous_brick_field.gd  -> iniş hızı, satır doluluğu
#   level_generator.gd         -> patlayıcı/zırh oranı
#   side_attacker_spawner.gd   -> saldırgan sıklığı
#   ball.gd                    -> top hızı
#
# NOT: static gövdeden autoload çağrılmaz (Godot sınıfı autoload'lar
# kaydolmadan derleyebilir). Gereken her şey parametreyle gelir.

const SECTOR_COUNT := 7

const MODIFIERS := {
	1: {
		"name": "SESSİZ KUŞAK",
		"tagline": "Tanıdık sular. Henüz.",
		"descent_scale": 1.0,
		"row_fill_bonus": 0.0,
		"explosive_bonus": 0.0,
		"ball_speed_scale": 1.0,
		"attacker_scale": 1.0,
	},
	2: {
		"name": "ENKAZ TARLASI",
		"tagline": "Patlayıcı kalıntılar her yerde.",
		"descent_scale": 1.0,
		"row_fill_bonus": 0.0,
		# Patlayıcı tuğla oranı belirgin artar — zincirleme fırsatı ve risk.
		"explosive_bonus": 0.06,
		"ball_speed_scale": 1.0,
		"attacker_scale": 1.0,
	},
	3: {
		"name": "DÜŞÜK YERÇEKİMİ",
		"tagline": "Top hızlanıyor, satırlar yavaşlıyor.",
		# Satırlar yavaşlar ama top hızlanır: daha çok tuğla, daha az tepki süresi.
		"descent_scale": 1.12,
		"row_fill_bonus": 0.0,
		"explosive_bonus": 0.0,
		"ball_speed_scale": 1.15,
		"attacker_scale": 1.0,
	},
	4: {
		"name": "SIKIŞMA BÖLGESİ",
		"tagline": "Satırlar daha dolu geliyor.",
		"descent_scale": 1.06,
		"row_fill_bonus": 0.05,
		"explosive_bonus": 0.0,
		"ball_speed_scale": 1.0,
		"attacker_scale": 1.0,
	},
	5: {
		"name": "AVCI KUŞAĞI",
		"tagline": "Yan taretler iki katı sıklıkta.",
		# Saldırgan aralığı kısalır (daha sık), karşılığında satırlar yavaşlar.
		"descent_scale": 1.10,
		"row_fill_bonus": 0.0,
		"explosive_bonus": 0.0,
		"ball_speed_scale": 1.0,
		"attacker_scale": 0.55,
	},
	6: {
		"name": "ÇÖKÜŞ HATTI",
		"tagline": "Her şey hızlanıyor.",
		# descent_scale burada NÖTR bırakıldı — bkz. aşağıdaki not.
		# Baskı, doygun olmayan eksenlere taşındı.
		"descent_scale": 1.0,
		"row_fill_bonus": 0.05,
		"explosive_bonus": 0.02,
		"ball_speed_scale": 1.05,
		"attacker_scale": 0.78,
	},
	7: {
		"name": "BOŞLUĞUN DİBİ",
		"tagline": "Buradan sonrası kayıt dışı.",
		"descent_scale": 1.0,
		"row_fill_bonus": 0.08,
		"explosive_bonus": 0.04,
		"ball_speed_scale": 1.08,
		"attacker_scale": 0.66,
	},
}

## NOT — SEKTÖR 6 VE 7'DE NEDEN descent_scale YOK (Faz 5.3 ölçümü)
##
## Bu iki sektörün eski değerleri 0.90 ve 0.86 idi. Ölçünce görüldü ki
## ikisi de ÖLÜ SAYIYDI: sektör 6 depth 21'de, sektör 7 depth 25'te
## başlıyor; iniş tabanı (`minimum_safe_step_interval`) ise ağır senaryoda
## depth 9'da bağlıyor. Yani bu çarpanlar hiçbir zaman oyuncuya ulaşmadı.
##
## Sayıyı büyütmek çözüm değil — taban yine yutar. Baskı doygun olmayan
## eksenlere taşındı: satır doluluğu, saldırgan sıklığı, top hızı.
## Bu üçünün tavanı yok, farkları oyuncuya doğrudan ulaşır.
##
## Yeni sektör eklerken: derinlik 9'un ötesinde descent_scale ile baskı
## kurmaya çalışma, işe yaramaz.


static func get_sector_for_depth(depth: int) -> int:
	# Dört depth'te bir sektör; yedinci sektör depth 25'ten sonrasını kapsar.
	return clampi(int(floor(float(depth - 1) / 4.0)) + 1, 1, SECTOR_COUNT)


static func get_data(sector: int) -> Dictionary:
	return MODIFIERS.get(clampi(sector, 1, SECTOR_COUNT), MODIFIERS[1])


## NOT: 'get_name' Object'in yerlesik metoduyla cakisir; bu yuzden ozel ad.
static func get_sector_name(sector: int) -> String:
	return String(get_data(sector).get("name", "SEKTÖR"))


static func get_tagline(sector: int) -> String:
	return String(get_data(sector).get("tagline", ""))


static func get_descent_scale(sector: int) -> float:
	return float(get_data(sector).get("descent_scale", 1.0))


static func get_row_fill_bonus(sector: int) -> float:
	return float(get_data(sector).get("row_fill_bonus", 0.0))


static func get_explosive_bonus(sector: int) -> float:
	return float(get_data(sector).get("explosive_bonus", 0.0))


static func get_ball_speed_scale(sector: int) -> float:
	return float(get_data(sector).get("ball_speed_scale", 1.0))


static func get_attacker_scale(sector: int) -> float:
	return float(get_data(sector).get("attacker_scale", 1.0))


## Sektörün oynanışa etkisi var mı? (Sektör 1 nötr.)
static func has_effect(sector: int) -> bool:
	var data := get_data(sector)
	return not (
		is_equal_approx(float(data.get("descent_scale", 1.0)), 1.0)
		and is_equal_approx(float(data.get("row_fill_bonus", 0.0)), 0.0)
		and is_equal_approx(float(data.get("explosive_bonus", 0.0)), 0.0)
		and is_equal_approx(float(data.get("ball_speed_scale", 1.0)), 1.0)
		and is_equal_approx(float(data.get("attacker_scale", 1.0)), 1.0)
	)
