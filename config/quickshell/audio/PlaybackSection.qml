pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    id: section

    property bool expanded: false
    // Include playback streams only; microphone capture belongs to the input section
    readonly property var streams: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioOutStream)

    spacing: 4

    MenuButton {
        id: heading

        text: "APPLICATIONS (" + section.streams.length + ")"
        Layout.fillWidth: true
        Layout.topMargin: 6
        onClicked: section.expanded = !section.expanded
        contentItem: RowLayout {
            spacing: 8

            Text {
                text: section.expanded ? "▾" : "▸"
                font.family: heading.font.family
                font.pointSize: 16
                color: heading.highlightedRow ? "#24272e" : "#abb2bf"
            }

            Text {
                text: heading.text
                font: heading.font
                color: heading.highlightedRow ? "#24272e" : "#5c6370"
                Layout.fillWidth: true
            }
        }
    }

    ColumnLayout {
        visible: section.expanded
        Layout.fillWidth: true
        spacing: 12

        Text {
            visible: section.streams.length === 0
            text: "No playback streams"
            color: "#abb2bf"
            font.family: "Noto Sans Mono"
            font.pointSize: 10.5
            Layout.leftMargin: 8
        }

        Repeater {
            model: section.streams

            ColumnLayout {
                id: stream

                required property PwNode modelData
                readonly property bool ready: modelData !== null && modelData.ready

                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: {
                        if (!stream.ready)
                            return "Connecting…";
                        const node = stream.modelData;
                        return node.properties["application.name"] || node.description || node.name;
                    }
                    color: "#abb2bf"
                    font.family: "Noto Sans Mono"
                    font.pointSize: 10.5
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.topMargin: 6
                }

                Text {
                    text: {
                        // Playback apps send audio from the source end of each link
                        const links = Pipewire.linkGroups.values.filter(link => link.source === stream.modelData);
                        const outputs = links.map(link => link.target?.description || link.target?.name || "");
                        return "→ " + (outputs.filter(name => name).join(", ") || "No output connected");
                    }
                    color: "#abb2bf"
                    font.family: "Noto Sans Mono"
                    font.pointSize: 9
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                }

                VolumeControl {
                    // Its tracker also makes the app's name and properties available above
                    node: stream.modelData
                }
            }
        }
    }
}
