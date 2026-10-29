import QtQuick
import qs.Commons
import qs.Commons as Commons

// Small (22×22 by default) icon button used at the right edge of panel rows
// for inline actions — forget network, confirm passphrase, unpair device,
// etc. Two visual modes are supported via `hoverColor`:
//   - default: hoverColor === foreground → subtle foreground-tint hover
//   - urgent:  hoverColor === bar.urgent → red-tint hover for destructive
//              actions like forget/unpair
//
// `enabled` gates clicks and dims the icon. The component owns its own
// hover state visuals; mouse hover does NOT update any panel cursor state
// here because action buttons are not cursor targets — the row they live
// in is.
//
// Set `focusable: true` to make the button keyboard-tabbable with the
// shared hover-cursor/focus tokens. Use this
// in form contexts where Tab walks a list
// of controls; leave it false for the right-edge actions on panel rows
// where the row's CursorSurface owns the keyboard cursor.
//
// Set `hasCursor: true` to have the button render the same hover state as
// mouse hover — so a panel's keyboard cursor lands on it identically.
// Use this when a PanelActionButton is itself the cursor target (rather
// than living inside a CursorSurface row). Emits `hovered(bool)` on
// pointer enter/leave so the panel can update its cursor state to match.
BorderSurface {
  id: root

  property string iconText: ""
  property string tooltipText: ""
  property color foreground: Commons.Color.foreground
  property color hoverColor: foreground
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.icon
  property real size: Math.max(Style.space(22), fontSize + Style.spacing.sm * 2)

  property bool focusable: false
  property bool hasCursor: false
  property bool bordered: false

  signal clicked()
  signal hovered(bool isHovered)

  activeFocusOnTab: focusable
  Keys.onReturnPressed: if (focusable) root.clicked()
  Keys.onEnterPressed: if (focusable) root.clicked()
  Keys.onSpacePressed: if (focusable) root.clicked()

  implicitWidth: size
  implicitHeight: size
  radius: Anatomy.rowRadius

  readonly property bool _showFocusRing: focusable && activeFocus
  readonly property bool _hot: (mouse.containsMouse || root.hasCursor) && root.enabled
  // Destructive buttons pass a hoverColor different from foreground: they get
  // a red-tinted wash; everything else gets the anatomy white wash.
  readonly property bool _tinted: !Qt.colorEqual(hoverColor, foreground)

  // anatomy: borderless square icon button, white wash on hover, blue rim on
  // Tab focus, optional 0.6 px rim when `bordered`.
  color: _showFocusRing || _hot
    ? (_tinted ? Anatomy.alpha(hoverColor, 0.12) : Anatomy.hover)
    : "transparent"
  borderSpec: Border.none()
  border.width: _showFocusRing ? 1 : (bordered ? Anatomy.hairline : 0)
  border.color: _showFocusRing ? Anatomy.selectedRim : Anatomy.controlRim

  Behavior on color { ColorAnimation { duration: Anatomy.fast; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }

  Text {
    textFormat: Text.PlainText
    anchors.centerIn: parent
    text: root.iconText
    color: root.enabled
      ? (root._hot ? (root._tinted ? root.hoverColor : Anatomy.strong) : root.foreground)
      : Anatomy.lo
    font.family: root.fontFamily
    font.pixelSize: Math.round(root.fontSize)
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    enabled: root.enabled
    onContainsMouseChanged: root.hovered(containsMouse)
    onClicked: {
      if (root.focusable) root.forceActiveFocus()
      root.clicked()
    }
  }

  PanelToolTip {
    visible: root.tooltipText !== "" && mouse.containsMouse
    text: root.tooltipText
    fontFamily: root.fontFamily
  }
}
