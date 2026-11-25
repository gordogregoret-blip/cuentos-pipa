class_name UiTheme
extends RefCounted
## Paleta (docs/art/art-direction-brief.md) y tema de la interfaz.
## Texto de lectura de 40 px (mínimo pedido: 36 px).

const INK := Color("#4A2E22")
const CREAM := Color("#FFF6E8")
const WALL := Color("#D9EEE4")
const CORAL := Color("#F2836B")
const SUN := Color("#FFD86B")
const TEAL := Color("#5BB5A8")
const SKY := Color("#BFE4F2")
const GRASS := Color("#A8D59A")
const HIGHLIGHT := Color("#F59B2F")  # palabra que se está leyendo

const READ_SIZE := 40
const UI_SIZE := 40
const TITLE_SIZE := 64
const BUTTON := 112  # px de la base; 64 dp ≈ 96 px en un celular común

const NUNITO := preload("res://fonts/Nunito.ttf")
const ATKINSON := preload("res://fonts/AtkinsonHyperlegible-Regular.ttf")
const ATKINSON_BOLD := preload("res://fonts/AtkinsonHyperlegible-Bold.ttf")


static func reading_font(easy: bool) -> Font:
	if easy:
		return ATKINSON
	var f := FontVariation.new()
	f.base_font = NUNITO
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 600}
	return f


static func build(easy: bool) -> Theme:
	var t := Theme.new()
	t.default_font = reading_font(easy)
	t.default_font_size = UI_SIZE
	t.set_color("font_color", "Label", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		t.set_stylebox(state, "Button", _box(CREAM if state != "pressed" else SUN, 32))
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.4))
	t.set_stylebox("panel", "PanelContainer", _box(Color(CREAM, 0.94), 36))
	return t


static func _box(color: Color, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(radius)
	b.set_border_width_all(6)
	b.border_color = INK
	b.set_content_margin_all(20)
	return b


## Botón redondo con ícono SVG; su nombre accesible sale de la traducción.
static func icon_button(icon: String, label_key: String, size := BUTTON) -> Button:
	var b := Button.new()
	b.name = label_key
	b.icon = load("res://art/ui/%s.svg" % icon)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(size, size)
	b.tooltip_text = label_key
	b.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, empty)
	return b
