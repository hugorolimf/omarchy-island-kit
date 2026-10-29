import QtQuick

// The anatomy "lift": a cheap stand-in for the prototype's layered CSS shadow
// (outer 1 px dark ring + a few offset drops, plus a faint inner top light).
// Drop it inside the surface it lifts:
//   AnatomyLift { radius: card.radius }                // drop shadow (z -1)
//   AnatomyLift { radius: card.radius; inner: true }   // top highlight
// Plain Rectangles only, no blur or layer, so it costs nothing per frame.
Item {
  id: root

  property real radius: Anatomy.cardRadius
  property bool inner: false
  // Drop distance in px; panels use a deeper lift than buttons.
  property real depth: 6
  property real strength: 1.0

  anchors.fill: parent
  z: inner ? 1 : -1

  // Outer dark ring (0 0 0 1px #00000026).
  Rectangle {
    visible: !root.inner
    anchors.fill: parent
    anchors.margins: -1
    radius: root.radius + 1
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(0, 0, 0, 0.15 * root.strength)
  }

  Repeater {
    model: root.inner ? 0 : 3
    Rectangle {
      required property int index
      readonly property real off: root.depth * [0.17, 0.5, 1.0][index]
      anchors.fill: parent
      anchors.topMargin: off
      anchors.bottomMargin: -off
      anchors.leftMargin: off / 2
      anchors.rightMargin: off / 2
      radius: root.radius
      color: Qt.rgba(0, 0, 0, 0.08 * root.strength)
    }
  }

  // Inner light: inset 0 1px 0 #ffffff0a + inset ring #ffffff06.
  Rectangle {
    visible: root.inner
    anchors.fill: parent
    radius: root.radius
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.024 * root.strength)
  }
  Rectangle {
    visible: root.inner
    x: root.radius
    width: Math.max(0, parent.width - root.radius * 2)
    height: 1
    color: Qt.rgba(1, 1, 1, 0.04 * root.strength)
  }
}
