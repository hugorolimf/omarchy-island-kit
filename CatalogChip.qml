import QtQuick
import qs.Commons
import "ui"

// Pill button: icon + label, accent for the main action.
Rectangle {
  id: chip
  property string label: ""
  property string iconPath: ""
  property bool accent: false
  property bool enabledChip: true
  signal clicked()
  height: Style.space(26)
  width: chipRow.implicitWidth + Style.space(18)
  radius: height / 2
  color: !chip.enabledChip ? "transparent" : chipArea.containsMouse ? (chip.accent ? Anatomy.toggleOn : Anatomy.hover) : (chip.accent ? Anatomy.selected : "transparent")
  border.width: Anatomy.hairline
  border.color: chip.accent && chip.enabledChip ? Anatomy.selectedRim : Anatomy.controlRim
  Behavior on color { ColorAnimation { duration: Anatomy.fast } }
  Row {
    id: chipRow
    anchors.centerIn: parent
    spacing: Style.space(5)
    AnatomyIcon {
      visible: chip.iconPath !== ""
      anchors.verticalCenter: parent.verticalCenter
      size: 12
      path: chip.iconPath
      color: chip.accent && chip.enabledChip ? Anatomy.blue : Anatomy.muted
    }
    Text {
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      text: chip.label
      color: chip.enabledChip ? Anatomy.text : Anatomy.muted
      font.family: Anatomy.sans
      font.pixelSize: 12
    }
  }
  MouseArea {
    id: chipArea
    anchors.fill: parent
    enabled: chip.enabledChip
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: chip.clicked()
  }
}
