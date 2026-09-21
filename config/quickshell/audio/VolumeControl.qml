import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire

RowLayout {
  id: control

  required property PwNode node
  readonly property bool available: {
    return node !== null && node.ready && node.audio !== null;
  }

  // Keep device and application controls subscribed to live volume/mute changes
  PwObjectTracker {
    objects: [control.node]
  }

  visible: control.available
  Layout.fillWidth: true
  Layout.leftMargin: 8
  spacing: 8

  Slider {
    id: volume

    Layout.fillWidth: true
    implicitHeight: 32
    from: 0
    to: 1
    stepSize: 0.01
    // Quickshell already uses the same volume scale as wpctl; 1 means 100%
    value: control.available ? control.node.audio.volume : 0
    // Write only user changes, not updates received through the value binding
    onMoved: {
      if (control.available)
        control.node.audio.volume = value;
    }
    background: Rectangle {
      x: volume.leftPadding
      y: volume.topPadding + volume.availableHeight / 2 - height / 2
      width: volume.availableWidth
      height: 4
      radius: 2
      color: "#4b5263"

      Rectangle {
        width: volume.visualPosition * parent.width
        height: parent.height
        radius: 2
        color: "#61afef"
      }
    }
    handle: Rectangle {
      x: {
        const travel = volume.availableWidth - width;
        return volume.leftPadding + volume.visualPosition * travel;
      }
      y: volume.topPadding + volume.availableHeight / 2 - height / 2
      width: 12
      height: 12
      radius: 6
      color: "#61afef"
    }
  }

  Text {
    text: {
      if (!control.available)
        return "";
      return Math.round(control.node.audio.volume * 100) + "%";
    }
    color: "#abb2bf"
    font.family: "Noto Sans Mono"
    font.pointSize: 10.5
    horizontalAlignment: Text.AlignRight
    Layout.preferredWidth: 42
  }

  MenuButton {
    id: mute

    readonly property bool muted: control.available && control.node.audio.muted

    text: muted ? "" : ""
    font.family: "Symbols Nerd Font"
    font.pointSize: 14
    Layout.preferredWidth: 36
    Accessible.name: muted ? "Unmute" : "Mute"
    contentItem: Text {
      text: mute.text
      font: mute.font
      color: {
        if (mute.highlightedRow)
          return "#24272e";
        return mute.muted ? "#e06c75" : "#abb2bf";
      }
      verticalAlignment: Text.AlignVCenter
      horizontalAlignment: Text.AlignHCenter
    }
    onClicked: {
      if (control.available)
        control.node.audio.muted = !control.node.audio.muted;
    }
  }
}
