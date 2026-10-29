import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Commons as Commons

// Styled wrapper around Qt Quick Controls ToolTip. Drop-in: declare inside
// the hovered item and bind `visible` to the hover state, e.g.
//   PanelToolTip {
//     visible: mouse.containsMouse
//     text: "Forget network"
//   }
//
// anatomy defaults (card, strong text, 0.6 px rim) replace the [tooltip] theme. Override
// the panel* properties per-instance only when you need a tooltip that
// intentionally diverges from the theme.
//
// Property names are prefixed `panel*` to avoid clashing with ToolTip's
// built-in `background`/`font` properties.
ToolTip {
  id: root

  // anatomy: small lifted card, strong sans text, 0.6 px rim.
  property color panelForeground: Anatomy.strong
  property color panelBackground: Anatomy.card
  property color panelBorder: Anatomy.controlRim
  property string fontFamily: Anatomy.sans
  property real fontSize: Style.font.bodySmall

  // No reserved inset: the rim is a 0.6 px native border.
  readonly property var panelBorderSpec: Border.none()

  delay: 400
  padding: 0

  enter: Transition {
    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Anatomy.fast; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease }
  }
  exit: Transition {
    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease }
  }

  background: Rectangle {
    color: root.panelBackground
    border.width: Anatomy.hairline
    border.color: root.panelBorder
    radius: Anatomy.rowRadius

    AnatomyLift { radius: parent.radius; depth: 4 }
  }

  contentItem: Text {
    textFormat: Text.PlainText
    text: root.text
    color: root.panelForeground
    font.family: root.fontFamily
    font.pixelSize: Math.round(root.fontSize)
    leftPadding: Border.left(root.panelBorderSpec) + Style.spacing.controlPaddingX
    rightPadding: Border.right(root.panelBorderSpec) + Style.spacing.controlPaddingX
    topPadding: Border.top(root.panelBorderSpec) + Style.spacing.controlPaddingY
    bottomPadding: Border.bottom(root.panelBorderSpec) + Style.spacing.controlPaddingY
  }
}
