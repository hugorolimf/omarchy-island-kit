import QtQuick
import qs.Commons
import qs.Commons as Commons

// anatomy: hairline divider between panel sections (0.6 px white at 6% in
// the prototype). A 1 px row at a lower alpha reads the same and never
// vanishes on fractional scales. `strength` keeps its meaning (relative to
// the stock 0.12) so callers asking for a firmer rule still get one.
Rectangle {
  id: root

  property color foreground: Commons.Color.foreground
  property real strength: 0.12

  width: parent ? parent.width : implicitWidth
  implicitWidth: 100
  implicitHeight: 1
  height: 1
  color: Qt.rgba(1, 1, 1, 0.04 * (strength / 0.12))
}
