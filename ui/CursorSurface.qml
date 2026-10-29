import QtQuick
import qs.Commons
import qs.Commons as Commons

// Shared chrome for keyboard-and-mouse-navigable rows inside a panel.
// Contract: items must NOT read `containsMouse` for color/border. Mouse
// hover updates the panel's cursor state at the root; visuals derive from
// `hasCursor` / `current`, so there is one highlight on screen at a time.
//
// anatomy (.rowi): borderless rows, a faint white wash under the cursor and
// a translucent blue for the current/selected row. `outline` is kept for
// compatibility (slider rows) and paints the same wash. `bordered` adds the
// 0.6 px control rim. `fill` / `currentFill` stay overridable.
BorderSurface {
  id: root

  property bool hasCursor: false
  property bool current: false
  property bool outline: false
  property bool bordered: false

  property color foreground: Commons.Color.foreground
  property color accent: Commons.Color.accent
  property color fill: Anatomy.hover
  property color currentFill: Anatomy.selected

  radius: Anatomy.rowRadius

  color: hasCursor ? fill : (current ? currentFill : "transparent")
  borderSpec: Border.none()
  border.width: root.bordered ? Anatomy.hairline : 0
  border.color: Anatomy.controlRim

  Behavior on color {
    ColorAnimation { duration: Anatomy.fast; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease }
  }
}
