# Prawn configuration for Chinese support
Prawn::Fonts::AFM.hide_m17n_warning = true

# Register Chinese font fallback
module PrawnChineseFont
  def self.font_path
    # Use Noto Sans CJK Regular font available on the system
    '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc'
  end
end
