import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Commons as Commons

// Single-line text input with the kit's focus + selection styling. Inherits
// from Qt Quick Controls TextField so the underlying type's API (text,
// placeholderText, accepted, editingFinished, validator, ...) is available
// to callers without re-exposing each property.
//
// Defaults bind to qs.Commons.Color so a caller with no theme overrides
// just works; foreground / accent / selectionTint can be overridden per
// instance. activeFocus and mouse hover / panel cursor use the same
// hover-cursor defaults, so text inputs match Button, Toggle, and Dropdown.
//
// Sizing is driven by font.pixelSize + verticalPadding. The default 30px
// implicitHeight fits dialog forms; inline callers (wifi's row-embedded
// passphrase prompt) drop verticalPadding to match a 22-26px row.
TextField {
  id: root

  property color foreground: Commons.Color.foreground
  property color accent: Commons.Color.accent
  property color selectionTint: Anatomy.selection
  property bool password: false
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.inputPaddingY

  // Panel-cursor flag. When true (and the field isn't already focused),
  // the background paints the shared hover/cursor state.
  // For mouse-enter/leave the consumer reads QQC TextField's inherited
  // `hovered` property (via onHoveredChanged) — we don't add a sibling
  // signal because the inherited property would shadow it.
  property bool hasCursor: false

  readonly property bool _focused: activeFocus
  readonly property bool _hot: hovered || hasCursor
  // anatomy: card fill, 0.6 px rim, blue rim on focus. Fixed 1 px reserve.
  readonly property var _borderSpec: Border.flat("transparent", 1)

  echoMode: password ? TextInput.Password : TextInput.Normal
  font.family: Anatomy.sans
  font.pixelSize: Style.font.body
  color: Anatomy.strong
  selectionColor: selectionTint
  selectedTextColor: Anatomy.strong
  placeholderTextColor: Anatomy.muted

  leftPadding: horizontalPadding + Border.left(_borderSpec)
  rightPadding: horizontalPadding + Border.right(_borderSpec)
  topPadding: verticalPadding + Border.top(_borderSpec)
  bottomPadding: verticalPadding + Border.bottom(_borderSpec)

  background: Rectangle {
    color: Anatomy.card
    radius: Anatomy.cardRadius
    border.width: root._focused ? 1 : Anatomy.hairline
    border.color: root._focused ? Anatomy.blue
      : (root._hot ? Qt.rgba(1, 1, 1, 0.16) : Anatomy.controlRim)

    Behavior on border.color { ColorAnimation { duration: Anatomy.fast; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
  }
}
