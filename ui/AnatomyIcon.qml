import QtQuick
import QtQuick.Shapes

// Stroke icon on the anatomy 24-unit grid (same path language as Island
// Bar): monochrome, round caps, colour only for state.
//   AnatomyIcon { path: Anatomy.icons.monitor; size: 16 }
// `paths` is joined into one ShapePath, so every part shares one colour.
Item {
  id: root

  property var paths: []
  property string path: ""
  property color color: Anatomy.hi
  property real size: 16
  // Stroke width in grid units (1.4 at 13-16 px reads like the prototype).
  property real strokeWidth: 1.4
  // a solid glyph (a logo) instead of a line one
  property bool filled: false

  readonly property string _d: path !== "" ? path : (Array.isArray(paths) ? paths.join(" ") : String(paths || ""))

  implicitWidth: size
  implicitHeight: size

  Shape {
    width: 24
    height: 24
    scale: root.size / 24
    transformOrigin: Item.TopLeft
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: root.filled ? "transparent" : root.color
      strokeWidth: root.strokeWidth
      fillColor: root.filled ? root.color : "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathSvg { path: root._d }
    }
  }
}
