import QtQuick
import QtQuick.Controls

// Shared Rofi-style appearance; device rows supply their own contentItem
Button {
  id: control

  // Focus stays after clicking; it must not keep the blue hover fill visible
  readonly property bool highlightedRow: hovered || down

  implicitHeight: 32
  padding: 8
  font.family: "Noto Sans Mono"
  font.pointSize: 10.5
  focusPolicy: Qt.StrongFocus
  background: Rectangle {
    radius: 4
    color: control.highlightedRow ? "#61afef" : "transparent"
  }
  contentItem: Text {
    text: control.text
    font: control.font
    color: control.highlightedRow ? "#24272e" : "#abb2bf"
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    elide: Text.ElideRight
  }
}
