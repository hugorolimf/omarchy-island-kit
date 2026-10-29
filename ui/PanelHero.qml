import QtQuick
import qs.Commons
import qs.Commons as Commons

Item {
  id: root

  property Component iconComponent: null
  property string title: ""
  property string meta: ""
  property string detail: ""
  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family
  property real iconSize: Style.font.display
  property real iconOpacity: 1.0
  property alias metaOpacity: metaText.opacity

  // Optional control pinned to the trailing edge of the hero — a ToggleSwitch,
  // a small button. The hero centers it against the labels and reserves the
  // space itself, so callers never do the geometry.
  property Component trailingControl: null

  // anatomy: sans title in strong, mono small-caps meta in muted.
  readonly property color dim: Anatomy.muted
  readonly property real trailingInset: trailingLoader.item && trailingLoader.item.visible ? trailingLoader.width + Style.space(12) : 0

  width: parent ? parent.width : implicitWidth
  implicitHeight: Math.max(iconLoader.implicitHeight, heroLabels.implicitHeight, trailingLoader.implicitHeight)

  Loader {
    id: iconLoader
    sourceComponent: root.iconComponent
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    opacity: root.iconOpacity
  }

  Column {
    id: heroLabels
    anchors.left: iconLoader.right
    anchors.leftMargin: Style.space(14)
    anchors.right: parent.right
    anchors.rightMargin: root.trailingInset
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(2)

    Row {
      id: titleRow
      visible: root.title !== "" || detailPill.visible
      width: parent.width

      Text {
        textFormat: Text.PlainText
        visible: root.title !== ""
        text: root.title
        width: Math.min(implicitWidth, Math.max(0, parent.width - (detailPill.visible ? detailPill.implicitWidth + Style.space(8) : 0)))
        color: Anatomy.strong
        font.family: Anatomy.sans
        font.pixelSize: Style.font.title
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }

      Item {
        width: Math.max(0, parent.width - parent.children[0].width - detailPill.implicitWidth)
        height: 1
      }

      BorderSurface {
        id: detailPill
        visible: root.detail !== ""
        implicitWidth: detailText.implicitWidth + Style.space(10)
        implicitHeight: detailText.implicitHeight + Style.space(4)
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        borderSpec: Border.none()
        border.width: Anatomy.hairline
        border.color: Anatomy.controlRim
        radius: Anatomy.chipRadius

        Text {
          id: detailText
          textFormat: Text.PlainText
          anchors.centerIn: parent
          text: root.detail
          color: Anatomy.text
          font.family: Anatomy.mono
          font.pixelSize: Style.font.caption
          font.weight: Font.Medium
        }
      }
    }

    Text {
      id: metaText
      textFormat: Text.PlainText
      width: parent.width
      text: root.meta.toUpperCase()
      visible: text !== ""
      color: root.dim
      font.family: Anatomy.mono
      font.pixelSize: Style.font.caption
      font.weight: Font.DemiBold
      font.letterSpacing: Anatomy.labelSpacing
      elide: Text.ElideRight
    }
  }

  Loader {
    id: trailingLoader
    sourceComponent: root.trailingControl
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
  }
}
