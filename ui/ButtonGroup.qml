import QtQuick
import qs.Commons
import qs.Commons as Commons

// Mutually-exclusive row of Buttons — the form-style "pick one of N"
// pattern (bar position top/right/bottom/left, theme preset chips, etc.).
// Emits `changed(value)` when the user activates a different option.
//
// `options` is either a plain string[] (label == value) or an array of
// { value, label, icon?, tooltip? } objects. Mixing is fine.
//
// Keyboard navigation. The group itself is a single Tab stop, not one
// stop per chip — so in a form that walks `activeFocusOnTab` items with
// Tab / j / k, the cursor enters the group as a unit. Once focused,
// h / l / Left / Right walks between chips and Enter / Space activates
// the current one. The selected chip is the default landing point so
// users see their existing choice on arrival.
//
// Panel-cursor consumers (the bar widget panels) drive `cursorIndex`
// directly and listen on `hovered` to sync the mouse — Tab focus and
// `cursorIndex` are independent; either one paints the chip's hot
// state, and the bar widget panels never give Tab focus to a
// ButtonGroup so they only see the cursorIndex path.
Row {
  id: root

  property var options: []
  property string value: ""
  property color foreground: Commons.Color.foreground
  property color background: Commons.Color.background
  property color accent: Commons.Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property bool focusable: true

  // -1 disables the external cursor highlight (the panel-cursor case).
  // Driven by a containing panel; the group's own Tab-focus h/l
  // tracking is internal and lives in _focusedIndex.
  property int cursorIndex: -1

  // Internal: which chip h / l / Left / Right is currently sitting on
  // when the group itself has Tab focus. Reset to the selected option
  // each time focus arrives so the user sees their existing choice.
  property int _focusedIndex: -1

  signal changed(string value)
  signal hovered(int index, bool isHovered)

  // anatomy (.seg): chips sit on one faint rail, 2 px apart, 2 px in.
  spacing: 2
  padding: 2

  // The rail is parented next to the Row (a Row child would be laid out as
  // one more chip) and follows the Row's geometry.
  Rectangle {
    parent: root.parent
    visible: root.visible && root.options.length > 0
    x: root.x
    y: root.y
    z: root.z - 1
    width: root.width
    height: root.height
    radius: Anatomy.rowRadius
    color: Anatomy.faint
    opacity: root.opacity
  }

  activeFocusOnTab: focusable

  function optionValue(o) {
    return (o && typeof o === "object") ? String(o.value) : String(o)
  }
  function optionLabel(o) {
    return (o && typeof o === "object" && o.label !== undefined) ? String(o.label) : String(o)
  }
  function optionIcon(o) {
    return (o && typeof o === "object" && o.icon) ? String(o.icon) : ""
  }
  function optionTooltip(o) {
    return (o && typeof o === "object" && o.tooltip) ? String(o.tooltip) : ""
  }

  function selectedOptionIndex() {
    for (var i = 0; i < options.length; i++)
      if (optionValue(options[i]) === value) return i
    return -1
  }

  function activateFocused() {
    if (_focusedIndex < 0 || _focusedIndex >= options.length) return
    var v = optionValue(options[_focusedIndex])
    root.changed(v)
  }

  onActiveFocusChanged: {
    if (activeFocus) {
      var idx = selectedOptionIndex()
      _focusedIndex = idx < 0 ? 0 : idx
    } else {
      _focusedIndex = -1
    }
  }

  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Left || event.key === Qt.Key_H
        || event.text === "h") {
      _focusedIndex = Math.max(0, (_focusedIndex < 0 ? 0 : _focusedIndex) - 1)
      event.accepted = true
    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L
        || event.text === "l") {
      var max = options.length - 1
      var next = (_focusedIndex < 0 ? 0 : _focusedIndex) + 1
      _focusedIndex = Math.min(max, next)
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || event.key === Qt.Key_Space) {
      activateFocused()
      event.accepted = true
    }
  }

  Repeater {
    model: root.options

    delegate: BorderSurface {
      id: chip
      required property var modelData
      required property int index

      readonly property bool isSelected: root.optionValue(modelData) === root.value
      // Chip lights up when either the external panel cursor lands here
      // or the group has Tab focus and h/l has walked to this index.
      readonly property bool hasCursor: root.cursorIndex === index
        || (root.activeFocus && root._focusedIndex === index)
      readonly property bool hot: chipMouse.containsMouse || hasCursor
      readonly property string iconText: root.optionIcon(modelData)
      readonly property string tooltipText: root.optionTooltip(modelData)

      implicitWidth: chipRow.implicitWidth + Style.spacing.controlPaddingX * 2
      implicitHeight: chipRow.implicitHeight + Style.spacing.sm * 2
      radius: Anatomy.chipRadius
      color: isSelected ? Anatomy.card : (hot ? Anatomy.hover : "transparent")
      borderSpec: Border.none()
      border.width: hasCursor && root.activeFocus ? 1 : 0
      border.color: Anatomy.selectedRim

      Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }

      AnatomyLift { visible: chip.isSelected; radius: chip.radius; depth: 3 }
      AnatomyLift { visible: chip.isSelected; radius: chip.radius; inner: true }

      Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: Style.spacing.sm

        Text {
          textFormat: Text.PlainText
          visible: chip.iconText !== ""
          text: chip.iconText
          color: chip.isSelected || chip.hot ? Anatomy.strong : Anatomy.muted
          font.family: root.fontFamily
          font.pixelSize: Math.round(root.fontSize)
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          textFormat: Text.PlainText
          text: root.optionLabel(chip.modelData)
          color: chip.isSelected || chip.hot ? Anatomy.strong : Anatomy.muted
          font.family: Anatomy.mono
          font.pixelSize: Math.round(Math.max(9, root.fontSize - 2))
          font.weight: Font.Medium
          font.letterSpacing: 0.5
          font.capitalization: Font.AllUppercase
          anchors.verticalCenter: parent.verticalCenter

          Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
        }
      }

      MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.changed(root.optionValue(chip.modelData))
      }

      HoverHandler {
        onHoveredChanged: root.hovered(chip.index, hovered)
      }

      PanelToolTip {
        visible: chip.tooltipText !== "" && chipMouse.containsMouse
        text: chip.tooltipText
      }
    }
  }
}
