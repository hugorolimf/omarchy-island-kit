import QtQuick
import qs.Commons

// A panel's on/off line, said in words (Island Inbox's Do Not Disturb row,
// made reusable): the stroke icon reacts, the title carries a state chip
// ("LIGADO", "MUDO"), the line below says what is happening now and
// cross-fades when it changes, and a switch sits on the trailing edge. The
// whole row is the switch; `alert` tints it in `tone` (red for a silenced
// or cut-off state), so the state reads from colour and from words.
//
//   StateHero {
//     title: "Bluetooth"; stateText: "LIGADO"; detail: "Conectado a AirPods."
//     iconPath: Anatomy.icons.bluetooth; marked: !on; checked: on
//     onToggled: root.toggleBluetooth()
//   }
//
// Icon: `iconPath` is always drawn; `layers` ([{ d, a }], keep the count
// fixed) fade to their alpha (volume waves, Wi-Fi bars); `markPath` (the
// slash by default) grows out from `markOrigin` while `marked`. Changing
// `checked` pops the icon, or swings it from its top with `motion: "swing"`.
Item {
  id: root

  property string title: ""
  property string stateText: ""
  property string detail: ""
  property string tooltip: ""

  property string iconPath: ""
  property var layers: []
  property bool marked: false
  property string markPath: Anatomy.icons.slash
  property point markOrigin: Qt.point(4, 4)
  // icon colour while not in alert; blue says "in use", like the bar
  property color iconColor: Anatomy.hi
  property string motion: "pop"

  property bool checked: false
  property bool alert: false
  property color tone: Anatomy.red
  property bool busy: false
  property bool hasCursor: false
  // a row without a switch (state only)
  property bool switchVisible: true

  signal toggled()
  signal hovered(bool isHovered)

  readonly property bool hot: hasCursor || area.containsMouse
  readonly property color accent: alert ? tone : Anatomy.blue

  implicitHeight: Style.space(54)
  width: parent ? parent.width : implicitWidth

  Rectangle {
    id: card
    anchors.fill: parent
    radius: Anatomy.cardRadius + 4
    color: root.alert ? Qt.rgba(root.tone.r, root.tone.g, root.tone.b, root.hot ? 0.13 : 0.09)
      : root.hot ? Qt.rgba(1, 1, 1, 0.065) : Qt.rgba(1, 1, 1, 0.035)
    border.width: Anatomy.hairline
    border.color: root.alert ? Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.4)
      : root.hasCursor ? Anatomy.controlRim : Anatomy.rim
    Behavior on color { ColorAnimation { duration: 260; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
    Behavior on border.color { ColorAnimation { duration: 260; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.switchVisible
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: root.hovered(containsMouse)
    onClicked: if (!root.busy) root.toggled()
  }

  PanelToolTip {
    visible: root.tooltip !== "" && area.containsMouse
    text: root.tooltip
    fontFamily: Anatomy.sans
  }

  // ---- icon
  Item {
    id: icon
    x: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    width: 22
    height: 22
    readonly property color ink: root.alert ? root.tone : root.iconColor
    property color shownInk: ink
    Behavior on shownInk { ColorAnimation { duration: 260; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }

    AnatomyIcon {
      anchors.fill: parent
      size: 22
      path: root.iconPath
      color: icon.shownInk
    }
    Repeater {
      model: root.layers.length
      AnatomyIcon {
        required property int index
        readonly property var spec: root.layers[index] || ({})
        anchors.fill: parent
        size: 22
        path: spec.d || ""
        color: icon.shownInk
        opacity: spec.a === undefined ? 1 : spec.a
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
      }
    }
    // the mark grows out of its origin as it fades in
    AnatomyIcon {
      id: mark
      anchors.fill: parent
      size: 22
      path: root.markPath
      color: icon.shownInk
      property real grow: root.marked ? 1 : 0
      Behavior on grow { NumberAnimation { duration: 340; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
      visible: grow > 0.01
      opacity: Math.min(1, grow * 1.6)
      transform: Scale {
        origin.x: root.markOrigin.x * 22 / 24
        origin.y: root.markOrigin.y * 22 / 24
        xScale: 0.15 + 0.85 * mark.grow
        yScale: 0.15 + 0.85 * mark.grow
      }
    }

    transform: [
      Rotation { id: swing; origin.x: 11; origin.y: 2; angle: 0 },
      Scale { id: pop; origin.x: 11; origin.y: 11; xScale: 1; yScale: 1 }
    ]
    SequentialAnimation {
      id: swingAnim
      NumberAnimation { target: swing; property: "angle"; to: -14; duration: 90; easing.type: Easing.OutCubic }
      NumberAnimation { target: swing; property: "angle"; to: 10; duration: 140; easing.type: Easing.InOutSine }
      NumberAnimation { target: swing; property: "angle"; to: -5; duration: 130; easing.type: Easing.InOutSine }
      NumberAnimation { target: swing; property: "angle"; to: 0; duration: 170; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
      id: popAnim
      ParallelAnimation {
        NumberAnimation { target: pop; property: "xScale"; to: 0.82; duration: 90; easing.type: Easing.InCubic }
        NumberAnimation { target: pop; property: "yScale"; to: 0.82; duration: 90; easing.type: Easing.InCubic }
      }
      ParallelAnimation {
        NumberAnimation { target: pop; property: "xScale"; to: 1; duration: 420; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease }
        NumberAnimation { target: pop; property: "yScale"; to: 1; duration: 420; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease }
      }
    }
  }
  onCheckedChanged: root.motion === "swing" ? swingAnim.restart() : popAnim.restart()

  // ---- words
  Column {
    anchors.left: icon.right
    anchors.leftMargin: Style.space(11)
    anchors.right: root.switchVisible ? knobTrack.left : parent.right
    anchors.rightMargin: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: 2

    Row {
      width: parent.width
      spacing: Style.space(7)
      Text {
        id: titleText
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        width: Math.min(implicitWidth, parent.width - (chip.visible ? chip.width + parent.spacing : 0))
        elide: Text.ElideRight
        color: Anatomy.strong
        font.family: Anatomy.sans
        font.pixelSize: 13
        font.weight: Font.DemiBold
      }
      // the state, written (not only the colour)
      Rectangle {
        id: chip
        visible: root.stateText !== ""
        anchors.verticalCenter: parent.verticalCenter
        width: chipText.implicitWidth + Style.space(10)
        height: Style.space(16)
        radius: height / 2
        color: root.alert ? Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.16)
          : root.checked ? Qt.rgba(Anatomy.blue.r, Anatomy.blue.g, Anatomy.blue.b, 0.13) : Qt.rgba(1, 1, 1, 0.06)
        Behavior on color { ColorAnimation { duration: 260 } }
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
        Text {
          id: chipText
          textFormat: Text.PlainText
          anchors.centerIn: parent
          text: root.stateText
          color: root.alert ? root.tone : root.checked ? Anatomy.blue : Anatomy.muted
          font.family: Anatomy.mono
          font.pixelSize: 9
          font.weight: Font.Medium
          font.letterSpacing: 0.6
          Behavior on color { ColorAnimation { duration: 260 } }
        }
      }
    }

    // what it does now; a new sentence cross-fades over the old one
    Item {
      id: detailBox
      width: parent.width
      height: Math.max(lineA.implicitHeight, lineB.implicitHeight)
      property bool showA: true
      property string shown: ""
      function swap(text) {
        if (text === shown) return
        shown = text
        if (showA) lineB.text = text
        else lineA.text = text
        showA = !showA
      }
      Component.onCompleted: { lineA.text = root.detail; shown = root.detail }
      Connections { target: root; function onDetailChanged() { detailBox.swap(root.detail) } }
      Text {
        id: lineA
        textFormat: Text.PlainText
        width: parent.width
        color: root.alert ? Anatomy.text : Anatomy.muted
        font.family: Anatomy.sans
        font.pixelSize: 11
        elide: Text.ElideRight
        opacity: detailBox.showA ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
      }
      Text {
        id: lineB
        textFormat: Text.PlainText
        width: parent.width
        color: lineA.color
        font.family: Anatomy.sans
        font.pixelSize: 11
        elide: Text.ElideRight
        opacity: detailBox.showA ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
      }
    }
  }

  // ---- the switch: blue knob when on; in alert it takes the tone
  Rectangle {
    id: knobTrack
    visible: root.switchVisible
    anchors.right: parent.right
    anchors.rightMargin: Style.space(14)
    anchors.verticalCenter: parent.verticalCenter
    width: 26
    height: 15
    radius: height / 2
    opacity: root.busy ? 0.6 : 1
    color: root.alert ? Qt.rgba(root.tone.r, root.tone.g, root.tone.b, 0.3)
      : root.checked ? Anatomy.toggleOn : Anatomy.faint
    Behavior on color { ColorAnimation { duration: 260; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
    Rectangle {
      width: 11
      height: 11
      radius: height / 2
      anchors.verticalCenter: parent.verticalCenter
      x: root.checked ? parent.width - width - 2 : 2
      color: root.alert ? root.tone : root.checked ? Anatomy.blue : root.hot ? Anatomy.hi : Anatomy.mid
      Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
      Behavior on color { ColorAnimation { duration: 260 } }
    }
  }
}
