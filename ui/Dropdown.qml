import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Commons as Commons

// Themed single-select dropdown. Trigger row paints with the kit's focus
// chrome; the popup anchors below and uses Commons.Color.popups.background +
// Commons.Color.popups.border so it reads as a panel surface rather than the
// platform-native ComboBox look.
//
// `options` accepts either a plain string[] or an array of
// { value, label } objects (label is what we render; value is what we
// emit). Mixing is fine — each row is interpreted independently.
//
// Keyboard: Tab to focus the trigger, Enter/Space opens, Esc closes,
// j/k or Up/Down walks options inside the open popup, Enter selects.
// A sibling SearchableDropdown reuses the same visuals but adds an
// embedded filter input — keep the two separate so each stays simple.
Item {
  id: root

  property string label: ""
  property string value: ""
  property var options: []

  // anatomy: card trigger with 0.6 px rim (blue on focus), panel-coloured
  // popup, white wash on the current option, blue check on the chosen one.
  property color foreground: Anatomy.strong
  property color background: Anatomy.panelFill
  property color popupBorder: Anatomy.rim
  property color accent: Anatomy.blue
  readonly property var popupBorderSpec: Border.none()
  property string fontFamily: Anatomy.sans
  property int rowHeight: Style.spacing.controlHeight
  property int popupRowHeight: Style.spacing.popupRowHeight
  property bool showLabel: true

  // Panel-cursor flag. When true, the trigger renders the shared
  // hover-cursor state. Active Qt focus defaults to the same visuals.
  // Emits `hovered(bool)` on pointer enter/leave so the panel can keep
  // its cursor state in sync with the mouse.
  property bool hasCursor: false

  // popupOpen + open()/close()/toggle() let a parent panel know when the
  // dropdown owns keys (its embedded ListView is active) and suspend its
  // own keyCatcher so j/k inside the popup don't double-drive the panel
  // cursor.
  readonly property bool popupOpen: popup.opened
  function open() { popup.open() }
  function close() { popup.close() }
  function toggle() { popup.opened ? popup.close() : popup.open() }

  signal changed(string value)
  signal hovered(bool isHovered)

  function optionValue(o) {
    return (o && typeof o === "object") ? String(o.value) : String(o)
  }
  function optionLabel(o) {
    return (o && typeof o === "object") ? String(o.label) : String(o)
  }
  function currentLabel() {
    for (var i = 0; i < options.length; i++) {
      if (optionValue(options[i]) === value) return optionLabel(options[i])
    }
    return value
  }

  implicitWidth: Style.spacing.dropdownWidth
  implicitHeight: showLabel && label !== "" ? rowHeight + Style.spacing.huge : rowHeight

  Column {
    anchors.fill: parent
    spacing: Style.spacing.labelGap

    Text {
      textFormat: Text.PlainText
      visible: root.showLabel && root.label !== ""
      text: root.label
      color: Anatomy.muted
      font.family: Anatomy.mono
      font.pixelSize: Style.font.caption
      font.weight: Font.DemiBold
      font.letterSpacing: Anatomy.labelSpacing
      font.capitalization: Font.AllUppercase
    }

    BorderSurface {
      id: trigger
      width: parent.width
      height: root.rowHeight
      radius: Anatomy.cardRadius

      readonly property bool _focused: trigger.activeFocus || popup.opened
      readonly property bool _hot: triggerHover.hovered || root.hasCursor

      color: trigger._hot ? Anatomy.face : Anatomy.card
      borderSpec: Border.none()
      border.width: trigger._focused ? 1 : Anatomy.hairline
      border.color: trigger._focused ? Anatomy.blue : (trigger._hot ? Qt.rgba(1, 1, 1, 0.16) : Anatomy.controlRim)

      Behavior on color { ColorAnimation { duration: Anatomy.fast; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }

      activeFocusOnTab: true

      HoverHandler {
        id: triggerHover
        onHoveredChanged: root.hovered(hovered)
      }

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
            || event.key === Qt.Key_Space || event.key === Qt.Key_Down) {
          popup.opened ? popup.close() : popup.open()
          event.accepted = true
        } else if (event.key === Qt.Key_Escape && popup.opened) {
          popup.close(); event.accepted = true
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.left: parent.left
        anchors.right: chevron.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: trigger.borderLeft + Style.spacing.controlPaddingX
        anchors.rightMargin: trigger.borderRight + Style.spacing.md
        text: root.currentLabel()
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }

      AnatomyIcon {
        id: chevron
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Style.spacing.controlGap
        path: Anatomy.icons.chevronDown
        size: Math.round(Style.font.body)
        color: Anatomy.muted
        rotation: popup.opened ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: Anatomy.base; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          trigger.forceActiveFocus()
          popup.opened ? popup.close() : popup.open()
        }
      }

      Popup {
        id: popup
        x: 0
        y: trigger.height + Style.spacing.xxs
        width: trigger.width
        implicitHeight: Math.min(root.options.length * root.popupRowHeight + Math.max(0, root.options.length - 1) * Style.spacing.labelGap + Style.spacing.xs * 2,
                                 root.popupRowHeight * 8 + 7 * Style.spacing.labelGap + Style.spacing.xs * 2)
        focus: true

        padding: Style.spacing.xs
        leftPadding: Style.spacing.xs
        rightPadding: Style.spacing.xs
        topPadding: Style.spacing.xs
        bottomPadding: Style.spacing.xs

        enter: Transition {
          NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Anatomy.fast; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease }
        }

        background: Rectangle {
          color: root.background
          border.width: Anatomy.hairline
          border.color: root.popupBorder
          radius: Anatomy.cardRadius

          AnatomyLift { radius: parent.radius; depth: 6 }
        }

        onOpened: {
          optionList.currentIndex = Math.max(0, optionList.indexOfValue(root.value))
          optionList.forceActiveFocus()
        }

        contentItem: ListView {
          id: optionList
          spacing: Style.spacing.labelGap

          Keys.priority: Keys.BeforeItem
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) { popup.close(); event.accepted = true }
            else if (event.key === Qt.Key_Down || event.text === "j") {
              optionList.currentIndex = Math.min(root.options.length - 1, optionList.currentIndex + 1)
              event.accepted = true
            } else if (event.key === Qt.Key_Up || event.text === "k") {
              optionList.currentIndex = Math.max(0, optionList.currentIndex - 1)
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              optionList.selectCurrent(); event.accepted = true
            }
          }
          implicitHeight: contentHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          model: root.options
          currentIndex: -1

          function indexOfValue(v) {
            for (var i = 0; i < root.options.length; i++)
              if (root.optionValue(root.options[i]) === v) return i
            return -1
          }

          function selectCurrent() {
            if (currentIndex < 0 || currentIndex >= root.options.length) return
            var v = root.optionValue(root.options[currentIndex])
            root.value = v
            root.changed(v)
            popup.close()
          }

          delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property bool chosen: root.optionValue(modelData) === root.value
            width: optionList.width
            height: root.popupRowHeight
            radius: Anatomy.chipRadius
            color: index === optionList.currentIndex
              ? Anatomy.hover
              : (chosen ? Anatomy.selected : "transparent")

            AnatomyIcon {
              visible: parent.chosen
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.md
              anchors.verticalCenter: parent.verticalCenter
              path: Anatomy.icons.check
              size: Math.round(Style.font.body)
              color: Anatomy.blue
              strokeWidth: 1.8
            }

            Text {
              textFormat: Text.PlainText
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.spacing.controlPaddingX
              anchors.rightMargin: Style.spacing.controlPaddingX + Style.font.body
              text: root.optionLabel(modelData)
              color: index === optionList.currentIndex || parent.chosen ? Anatomy.strong : Anatomy.text
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onPositionChanged: optionList.currentIndex = parent.index
              onClicked: optionList.selectCurrent()
            }
          }
        }
      }
    }
  }
}
