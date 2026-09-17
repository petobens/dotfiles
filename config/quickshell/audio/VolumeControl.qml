import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire

RowLayout {
    id: control

    required property PwNode node
    readonly property bool available: node !== null && node.ready && node.audio !== null

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
            x: volume.leftPadding + volume.visualPosition * (volume.availableWidth - width)
            y: volume.topPadding + volume.availableHeight / 2 - height / 2
            width: 12
            height: 12
            radius: 6
            color: "#61afef"
        }
    }

    Text {
        text: control.available ? Math.round(control.node.audio.volume * 100) + "%" : ""
        color: "#abb2bf"
        font.family: "Noto Sans Mono"
        font.pointSize: 10.5
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: 42
    }

    MenuButton {
        text: control.available && control.node.audio.muted ? "Unmute" : "Mute"
        Layout.preferredWidth: 76
        onClicked: {
            if (control.available)
                control.node.audio.muted = !control.node.audio.muted;
        }
    }
}
