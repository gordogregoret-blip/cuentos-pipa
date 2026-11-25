class_name BreathCycle
extends RefCounted
## Respiración del Rincón de calma: inflar 4 s, desinflar 4 s.

const IN_SECONDS := 4.0
const OUT_SECONDS := 4.0
const MIN_SCALE := 1.0
const MAX_SCALE := 1.4


static func phase_at(t: float) -> StringName:
	return &"in" if fposmod(t, IN_SECONDS + OUT_SECONDS) < IN_SECONDS else &"out"


static func scale_at(t: float) -> float:
	var c := fposmod(t, IN_SECONDS + OUT_SECONDS)
	var k: float
	if c < IN_SECONDS:
		k = c / IN_SECONDS
	else:
		k = 1.0 - (c - IN_SECONDS) / OUT_SECONDS
	# Curva suave (seno) para que no se vea mecánico.
	return lerpf(MIN_SCALE, MAX_SCALE, 0.5 - 0.5 * cos(k * PI))
