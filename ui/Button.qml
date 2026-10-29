import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Commons as Commons

// The button. One component for every clickable thing in the kit.
// States compose independently and are applied in priority order:
//
//   pressed (mouse down)         pressed wash, scale .97
//   activeFocus (Tab focus)      blue focus rim
//   hasCursor || hover           white wash (bordered: lifted card face)
//   selected / active            anatomy "pressed" chip: #1f2433 + blue rim
//   idle                         transparent, or lifted card if `bordered`
//
// anatomy: a bordered button is a small card (#131313 + lift) with mono
// caps text, like the prototype's <button>. `leftAlign` buttons are list
// rows, so they keep sentence-case sans text. Same API/signals as qs.Ui.
//
// Emits `hovered(bool)` so panels with their own keyboard cursor model
// can update state on mouse enter/leave.
BorderSurface {
  id: root

  property string text: ""
  property string iconText: ""
  property string tooltipText: ""

  // State flags (see comment above for paint priority).
  property bool selected: false
  property bool active: false
  property bool hasCursor: false
  property bool focusable: false
  property bool bordered: false

  // Colors. Defaults track the theme; per-instance overrides are honored.
  property color foreground: Commons.Color.foreground
  property color background: "transparent"
  property color accent: Commons.Color.accent

  // Sizing.
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property real iconSize: Style.font.icon
  property real iconRotation: 0
  property bool iconSpinning: false
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.controlPaddingY
  property bool leftAlign: false

  leftPadding: horizontalPadding
  rightPadding: horizontalPadding
  topPadding: verticalPadding
  bottomPadding: verticalPadding

  // Tooltip palette. Auto-rendered if tooltipText is set. Defaults pull
  // from [tooltip] in shell.toml; override per-instance only when a button
  // intentionally wants a tooltip that diverges from the theme.
  property color tooltipBackground: Anatomy.card
  property color tooltipForeground: Anatomy.strong
  property color tooltipBorder: Anatomy.controlRim

  signal clicked()
  signal rightClicked()
  signal hovered(bool isHovered)

  activeFocusOnTab: focusable
  Keys.onReturnPressed: if (focusable) root.clicked()
  Keys.onEnterPressed: if (focusable) root.clicked()
  Keys.onSpacePressed: if (focusable) root.clicked()

  // Reserve the largest border any visual state can paint. Otherwise a
  // borderless idle button grows by a pixel per side on hover/focus and
  // relayouts neighboring controls.
  implicitWidth: row.implicitWidth + horizontalPadding * 2 + _reservedBorderLeft + _reservedBorderRight
  implicitHeight: row.implicitHeight + verticalPadding * 2 + _reservedBorderTop + _reservedBorderBottom
  radius: Anatomy.cardRadius

  readonly property bool hot: mouseArea.containsMouse || hasCursor
  readonly property bool _showFocusRing: focusable && activeFocus
  readonly property bool _on: selected || active
  readonly property bool _caps: !leftAlign
  readonly property color _selectedColor: "#ffffff"
  // Constant 1 px reserve so state changes never relayout neighbours.
  readonly property real _reservedBorderTop: 1
  readonly property real _reservedBorderRight: 1
  readonly property real _reservedBorderBottom: 1
  readonly property real _reservedBorderLeft: 1
  readonly property real _reservedContentLeftInset: _reservedBorderLeft + leftPadding

  color: mouseArea.pressed ? (bordered ? Anatomy.face : Anatomy.pressed)
    : _on                  ? "#1f2433"
    : hot                  ? (bordered ? Anatomy.face : Anatomy.hover)
    : bordered             ? Anatomy.card
    : background

  borderSpec: Border.none()
  border.width: _showFocusRing || _on ? 1 : (bordered && hot ? Anatomy.hairline : 0)
  border.color: _showFocusRing || _on ? Anatomy.blue : Anatomy.controlRim
  scale: mouseArea.pressed ? 0.97 : 1.0

  Behavior on color { ColorAnimation { duration: Anatomy.fast; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
  Behavior on scale { NumberAnimation { duration: Anatomy.fast; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }

  AnatomyLift {
    visible: root.bordered && !root._on
    radius: root.radius
  }

  AnatomyLift {
    visible: root.bordered && !root._on
    radius: root.radius
    inner: true
  }

  PanelToolTip {
    visible: root.tooltipText !== "" && mouseArea.containsMouse
    text: root.tooltipText
    panelBackground: root.tooltipBackground
    panelForeground: root.tooltipForeground
    panelBorder: root.tooltipBorder
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: root.leftAlign ? parent.left : undefined
    anchors.leftMargin: root.leftAlign ? root._reservedContentLeftInset : 0
    anchors.horizontalCenter: root.leftAlign ? undefined : parent.horizontalCenter
    spacing: Style.spacing.controlGap

    Text {
      textFormat: Text.PlainText
      visible: root.iconText !== ""
      text: root.iconText
      color: root._on ? root._selectedColor : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Math.round(root.iconSize)
      rotation: root.iconSpinning ? 0 : root.iconRotation
      transformOrigin: Item.Center
      anchors.verticalCenter: parent.verticalCenter

      RotationAnimation on rotation {
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
        running: root.iconSpinning
      }
    }

    Text {
      textFormat: Text.PlainText
      visible: root.text !== ""
      text: root.text
      color: root._on ? root._selectedColor : (root.hot || root.bordered ? Anatomy.strong : root.foreground)
      font.family: root._caps ? Anatomy.mono : Anatomy.sans
      font.pixelSize: Math.round(root._caps ? Math.max(9, root.fontSize - 1) : root.fontSize)
      font.weight: Font.Medium
      font.letterSpacing: root._caps ? 0.5 : 0
      font.capitalization: root._caps ? Font.AllUppercase : Font.MixedCase
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(mouse) {
      if (root.focusable) root.forceActiveFocus()
      if (mouse.button === Qt.RightButton) root.rightClicked()
      else root.clicked()
    }
  }

  HoverHandler {
    onHoveredChanged: root.hovered(hovered)
  }
}
