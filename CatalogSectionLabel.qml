import QtQuick
import qs.Commons
import "ui"

// Small caps section title, with a hint on the right.
Item {
  property alias text: label.text
  property string hint: ""
  height: Style.space(28)
  Rectangle { width: parent.width; height: 1; color: Anatomy.rule; anchors.top: parent.top; anchors.topMargin: Style.space(4) }
  Text {
    id: label
    textFormat: Text.PlainText
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.space(4)
    color: Anatomy.muted
    font.family: Anatomy.mono
    font.pixelSize: 10
    font.weight: Font.DemiBold
    font.letterSpacing: Anatomy.labelSpacing
  }
  Text {
    textFormat: Text.PlainText
    visible: parent.hint !== ""
    anchors.right: parent.right
    anchors.rightMargin: Style.space(2)
    anchors.baseline: label.baseline
    text: parent.hint
    color: Anatomy.muted
    font.family: Anatomy.mono
    font.pixelSize: 9
    font.letterSpacing: Anatomy.labelSpacing
  }
}
