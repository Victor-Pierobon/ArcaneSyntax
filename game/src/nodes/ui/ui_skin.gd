class_name UiSkin
extends RefCounted
## A arte da interface (spec ART-brilho, regras 10 e 11): a moldura 9-slice `ui/moldura` nos painéis e
## o logo `ui/logo` no menu inicial. Sem os arquivos, cada painel fica com o estilo provisório dele.

## Margem do 9-slice da moldura de 48×48 (os cantos ficam inteiros).
const FRAME_MARGIN := 16.0
const CONTENT_MARGIN := 12.0


## A moldura, se existir; senão, `fallback`.
static func panel_style(fallback: StyleBox) -> StyleBox:
	var frame := ArtLibrary.texture("ui", "moldura")
	if frame == null:
		return fallback
	var style := StyleBoxTexture.new()
	style.texture = frame
	style.texture_margin_left = FRAME_MARGIN
	style.texture_margin_top = FRAME_MARGIN
	style.texture_margin_right = FRAME_MARGIN
	style.texture_margin_bottom = FRAME_MARGIN
	style.set_content_margin_all(CONTENT_MARGIN)
	return style


static func logo() -> Texture2D:
	return ArtLibrary.texture("ui", "logo")
