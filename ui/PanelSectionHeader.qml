import QtQuick
import qs.Commons
import qs.Commons as Commons

// anatomy section label ("BRILHO", "MONITORES"): mono, caps, 10-11 px,
// muted, tracked out. The mono family and muted tone are the anatomy rule,
// so `foreground` / `fontFamily` are kept for API compatibility only.
Text {
  id: root

  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.caption

  // Callers bind `text` from outside this file, so the default has to be set
  // here. AutoText would let a section title that happens to carry a device or
  // network name promote itself to rich text.
  textFormat: Text.PlainText
  color: Anatomy.muted
  font.family: Anatomy.mono
  font.pixelSize: Math.round(fontSize)
  font.weight: Font.DemiBold
  font.letterSpacing: Anatomy.labelSpacing
  font.capitalization: Font.AllUppercase

  // Reserve glyph overshoot so a header at the top of a clipping list is
  // never beheaded (JetBrainsMono runs ~10% past its ascent).
  topPadding: Math.ceil(fontSize * 0.15)
}
