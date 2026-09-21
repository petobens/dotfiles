import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

ShellRoot {
  id: root

  // The launcher chooses the clicked monitor or the keyboard's monitor
  property string screenName: Quickshell.env("AUDIO_MENU_SCREEN")

  // List audio devices, excluding applications' playback/recording streams
  readonly property var outputs: Pipewire.nodes.values.filter(node => {
    return !node.isStream && node.isSink && node.audio;
  })
  readonly property var inputs: Pipewire.nodes.values.filter(node => {
    return !node.isStream && !node.isSink && node.audio;
  })

  IpcHandler {
    target: "audio"

    // Reuse the popup on another monitor; a second launch here closes it
    function toggle(screenName: string): void {
      if (panel.screen.name === screenName) {
        // Let the IPC reply reach the launcher before exiting
        Qt.callLater(Qt.quit);
      } else {
        // Release the old surface's grab before switching monitors
        focusGrab.active = false;
        root.screenName = screenName;
        Qt.callLater(() => focusGrab.active = true);
      }
    }
  }

  // Quickshell creates PanelWindow despite its uncreatable metadata
  PanelWindow { // qmllint disable uncreatable-type
    id: panel

    screen: {
      const selected = Quickshell.screens.find(screen => {
        return screen.name === root.screenName;
      });
      return selected ?? Quickshell.screens[0];
    }
    anchors.top: true
    anchors.right: true
    // Qt tooling cannot resolve Quickshell's Margins type
    margins.top: 4 // qmllint disable unqualified unresolved-type
    margins.right: 4
    // Respect Waybar's reserved space without reserving any for this popup
    exclusiveZone: 0
    implicitWidth: 400
    implicitHeight: Math.min(content.implicitHeight + 18, screen.height - 60)
    color: "transparent"
    WlrLayershell.namespace: "audio-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
      id: focusGrab

      windows: [panel]
      active: true
      // Hyprland clears the grab when the user clicks outside the popup
      onCleared: Qt.quit()
    }

    Rectangle {
      anchors.fill: parent
      radius: 8
      color: "#24272e"
      border.width: 1
      border.color: "#4b5263"

      ScrollView {
        id: scroll

        anchors.fill: parent
        anchors.margins: 9
        contentWidth: availableWidth
        clip: true
        focus: true

        Keys.onPressed: event => {
          const key = event.key;
          const ctrl = event.modifiers & Qt.ControlModifier;
          const ctrlNext = ctrl && [Qt.Key_J, Qt.Key_N].includes(key);
          const ctrlPrev = ctrl && [Qt.Key_K, Qt.Key_P].includes(key);
          const next = key === Qt.Key_Down || ctrlNext;
          const previous = key === Qt.Key_Up || ctrlPrev;
          if (key === Qt.Key_Escape || (ctrl && key === Qt.Key_C)) {
            Qt.quit();
            event.accepted = true;
          } else if (next || previous) {
            // Reuse the tab order for Rofi-style navigation
            const window = panel.contentItem.Window.window;
            const focused = window.activeFocusItem || scroll;
            const target = focused.nextItemInFocusChain(next);
            target.forceActiveFocus(Qt.TabFocusReason);
            event.accepted = true;
          }
        }

        ColumnLayout {
          id: content

          width: scroll.availableWidth
          spacing: 8

          RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8

            Text {
              text: "Audio"
              color: "#abb2bf"
              font.family: "Noto Sans Mono"
              font.pointSize: 10.5
              font.bold: true
              Layout.fillWidth: true
            }

            MenuButton {
              text: "×"
              onClicked: Qt.quit()
            }
          }

          AudioSection {
            input: false
            nodes: root.outputs
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: "#4b5263"
          }

          AudioSection {
            input: true
            nodes: root.inputs
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: "#4b5263"
          }

          PlaybackSection {
            Layout.fillWidth: true
          }
        }
      }
    }
  }
}
