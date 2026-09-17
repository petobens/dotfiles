// Let each repeated device row access the enclosing section's properties
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
  id: section

  required property bool input
  required property var nodes
  // This binding follows the default device when it changes
  readonly property PwNode current: {
    if (input)
      return Pipewire.defaultAudioSource;
    return Pipewire.defaultAudioSink;
  }

  spacing: 4

  Text {
    text: section.input ? "INPUT" : "OUTPUT"
    color: "#5c6370"
    font.family: "Noto Sans Mono"
    font.pointSize: 10.5
    Layout.leftMargin: 8
    Layout.topMargin: 6
  }

  Repeater {
    model: section.nodes

    MenuButton {
      id: device

      // Repeater supplies one PipeWire node as modelData for each row
      required property PwNode modelData
      readonly property bool isDefault: section.current === modelData

      Layout.fillWidth: true
      onClicked: {
        // Request a default; the marker follows PipeWire's actual default
        if (section.input)
          Pipewire.preferredDefaultAudioSource = modelData;
        else
          Pipewire.preferredDefaultAudioSink = modelData;
      }
      contentItem: RowLayout {
        spacing: 8

        Text {
          text: device.isDefault ? "" : ""
          color: device.highlightedRow ? "#24272e" : "#98c379"
          font.family: "Symbols Nerd Font"
          font.pointSize: 8
          horizontalAlignment: Text.AlignHCenter
          Layout.preferredWidth: 16
        }
        Text {
          text: {
            // A disconnected node can disappear before its row is removed
            const node = device.modelData;
            const name = node?.description || node?.name || "";
            return String(name).replace(/ Analog Stereo$/, "");
          }
          color: device.highlightedRow ? "#24272e" : "#abb2bf"
          font: device.font
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }
    }
  }

  Text {
    visible: section.nodes.length === 0
    text: Pipewire.ready ? "No devices available" : "Connecting to audio…"
    color: "#abb2bf"
    font.family: "Noto Sans Mono"
    font.pointSize: 10.5
    Layout.leftMargin: 8
  }

  VolumeControl {
    node: section.current
  }
}
