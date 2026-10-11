pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  // Assign letters in grid order, starting with the home row
  readonly property string shortcuts: "asdfghjkl;qwertyuiopzxcvbnm"

  // Hide the overlay before focusing the window through the existing helper
  function activate(index: int): void {
    const window = grid.model[index];
    const address = window?.HyprlandToplevel.address;
    if (!address)
      return;
    panel.visible = false;
    focusWindow.command = [Quickshell.env("HOME")
                           + "/.config/hypr/scripts/focus_window", "0x"
                           + address];
    focusWindow.running = true;
  }

  Process {
    id: focusWindow
  }

  // Keep the shell loaded between uses to avoid repeating startup work
  IpcHandler {
    target: "expose"
    function toggle(): void {
      if (panel.visible) {
        panel.visible = false;
        return;
      }
      search.text = "";
      search.searching = false;
      help.visible = false;
      grid.initialSelectionPending = true;
      panel.visible = true;
      search.forceActiveFocus();
      Qt.callLater(grid.selectInitialWindow);
    }
  }

  PanelWindow { // qmllint disable uncreatable-type
    id: panel

    screen: Quickshell.screens.find(screen => screen.name
                                              === Hyprland.focusedMonitor
                                              ?.name) ?? Quickshell.screens[0]
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "#f224272e"
    WlrLayershell.namespace: "expose"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Column {
      id: content

      readonly property real availableHeight: panel.height - 48 - search.height
                                              - spacing - (help.visible
                                                           ? help.height
                                                             + spacing : 0)

      anchors.top: parent.top
      anchors.topMargin: 24
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width - 48
      spacing: 16

      TextField {
        id: search

        property bool searching: false

        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, 640)
        height: 44
        horizontalAlignment: TextInput.AlignHCenter
        leftPadding: 12
        rightPadding: 12
        // Qt hides its centered placeholder on focus, so draw our own hint
        Text {
          anchors.fill: parent
          anchors.margins: 12
          visible: !search.length && !search.preeditText
          text: search.searching ? "Search windows…" :
                                   "/  Search windows   ·   ?  Keyboard shortcuts"
          font: search.font
          color: "#5c6370"
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }
        background: Rectangle {
          radius: 8
          color: "#282c34"
          border.color: search.searching ? "#61afef" : "#4b5263"
        }
        focus: true
        color: "#abb2bf"
        font.family: "Noto Sans"
        font.pixelSize: 22
        clip: true
        selectByMouse: true
        readOnly: !searching
        onPressed: {
          searching = true;
          forceActiveFocus();
        }
        onTextChanged: {
          grid.currentIndex = 0;
          grid.positionViewAtBeginning();
        }

        // Outside search, letters select windows; in search, they enter text
        Keys.onPressed: event => {
          grid.initialSelectionPending = false;
          const key = event.key;
          const ctrl = event.modifiers & Qt.ControlModifier;
          let step = 0;
          if (ctrl && key === Qt.Key_C) {
            panel.visible = false;
          } else if (!searching && key === Qt.Key_Question) {
            help.visible = !help.visible;
          } else if (key === Qt.Key_Escape) {
            if (help.visible) {
              help.visible = false;
            } else if (searching) {
              text = "";
              searching = false;
            } else {
              panel.visible = false;
            }
          } else if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            root.activate(grid.currentIndex);
          } else if (key === Qt.Key_Tab || key === Qt.Key_Backtab) {
            const backward = key === Qt.Key_Backtab || (event.modifiers
                                                        & Qt.ShiftModifier);
            step = backward ? -1 : 1;
          } else if (ctrl && (key === Qt.Key_N || key === Qt.Key_P)) {
            step = key === Qt.Key_N ? 1 : -1;
          } else if ((!searching && key === Qt.Key_Left) || (ctrl && key
                                                             === Qt.Key_H)) {
            step = -1;
          } else if ((!searching && key === Qt.Key_Right) || (ctrl && key
                                                              === Qt.Key_L)) {
            step = 1;
          } else if (key === Qt.Key_Up || (ctrl && key === Qt.Key_K)) {
            step = -grid.columns;
          } else if (key === Qt.Key_Down || (ctrl && key === Qt.Key_J)) {
            step = grid.columns;
          } else if (!searching && key === Qt.Key_Slash) {
            searching = true;
          } else if (!searching && event.modifiers === Qt.NoModifier
                     && event.text.length === 1) {
            root.activate(root.shortcuts.indexOf(event.text.toLowerCase()));
          } else {
            return;
          }
          // Stop at either end and scroll the selected card into view
          if (step && grid.count) {
            grid.currentIndex = Math.max(0, Math.min(grid.count - 1, grid.currentIndex
                                                     + step));
            grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
          }
          event.accepted = true;
        }
      }

      Text {
        id: help

        width: parent.width
        visible: false
        color: "#5c6370"
        font.family: "Noto Sans"
        font.pixelSize: 17
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "Letter / click: open window   ·   Enter: open selection   ·   Tab / Shift+Tab or Ctrl+N/P: next / previous   ·   Arrows or Ctrl+H/J/K/L: navigate\n"
              + "/: search   ·   ?: toggle help outside search   ·   Esc: dismiss help → clear search → close   ·   Ctrl+C: close"
      }

      GridView {
        id: grid

        property bool initialSelectionPending: true

        // Favor large previews: at most three columns, fewer on narrow screens
        readonly property int columns: Math.max(1, Math.min(3, count, Math.floor(
                                                              width / 360)))
        readonly property int rows: Math.max(1, Math.ceil(count / columns))

        width: parent.width
        height: Math.min(content.availableHeight, rows * cellHeight)
        clip: true
        ScrollBar.vertical: ScrollBar {
          policy: ScrollBar.AsNeeded
          visible: grid.contentHeight > grid.height
          minimumSize: 0.08
          width: 10
          padding: 3
          background: Item {}
          contentItem: Rectangle {
            radius: 2
            color: "#4b5263"
          }
        }
        cellWidth: width / columns
        // Fit up to three rows on screen; additional rows remain scrollable
        cellHeight: Math.min(cellWidth * 0.85, content.availableHeight
                             / Math.min(rows, 3))
        model: ToplevelManager.toplevels.values.filter(window => {
          const query = search.text.toLowerCase();
          return (window.title + " " + window.appId).toLowerCase().includes(
                query);
        }).sort((a, b) => {
          const workspaceA = a.HyprlandToplevel.handle?.workspace?.id
                ?? Infinity;
          const workspaceB = b.HyprlandToplevel.handle?.workspace?.id
                ?? Infinity;
          if (workspaceA !== workspaceB)
            return workspaceA - workspaceB;
          // Window addresses keep the order stable within each workspace
          return a.HyprlandToplevel.address.localeCompare(
                b.HyprlandToplevel.address);
        })
        readonly property int focusedIndex: model.indexOf(
                                              ToplevelManager.activeToplevel)
        function selectInitialWindow(): void {
          if (!initialSelectionPending || focusedIndex < 0)
            return;
          initialSelectionPending = false;
          currentIndex = focusedIndex;
          positionViewAtIndex(currentIndex, GridView.Contain);
        }
        onFocusedIndexChanged: Qt.callLater(selectInitialWindow)
        onCountChanged: currentIndex = Math.min(Math.max(0, currentIndex),
                                                count - 1)

        delegate: Rectangle {
          id: card

          required property Toplevel modelData
          required property int index

          width: grid.cellWidth - 16
          height: grid.cellHeight - 16
          radius: 8
          color: "#282c34"
          border.width: 2
          border.color: index === grid.currentIndex ? "#61afef" : "#4b5263"

          ScreencopyView {
            anchors.centerIn: preview
            captureSource: card.modelData
            // Pause capture when hidden or outside the visible grid
            live: panel.visible && card.y < grid.contentY + grid.height
                  && card.y + card.height > grid.contentY
            constraintSize: Qt.size(preview.width, preview.height)
          }

          Item {
            id: preview
            anchors {
              top: parent.top
              left: parent.left
              right: parent.right
              margins: 10
            }
            // Reserve space below the preview for the title and shortcut badge
            height: parent.height - 54
          }

          Text {
            id: workspaceLabel

            anchors {
              bottom: parent.bottom
              left: parent.left
              margins: 12
            }
            text: "[" + (card.modelData.HyprlandToplevel.handle?.workspace
                         ?.name ?? "?") + "]"
            textFormat: Text.PlainText
            color: "#abb2bf"
            font.family: "Noto Sans"
            font.pixelSize: 17
            font.bold: true
          }

          Text {
            anchors {
              bottom: parent.bottom
              left: workspaceLabel.right
              right: parent.right
              margins: 12
              leftMargin: 6
            }
            text: card.modelData.title
            anchors.rightMargin: shortcut.visible ? 68 : 12
            textFormat: Text.PlainText
            color: "#abb2bf"
            font.family: "Noto Sans"
            font.pixelSize: 17
            elide: Text.ElideRight
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.activate(card.index)
          }

          Image {
            anchors {
              top: parent.top
              right: parent.right
              margins: 12
              topMargin: 6
            }
            width: 48
            height: 48
            sourceSize: Qt.size(width * panel.screen.devicePixelRatio, height
                                * panel.screen.devicePixelRatio)
            fillMode: Image.PreserveAspectFit
            source: Quickshell.iconPath(DesktopEntries.heuristicLookup(
                                          card.modelData.appId)?.icon
                                        || card.modelData.appId,
                                        "application-x-executable")
          }

          Rectangle {
            id: shortcut

            anchors {
              bottom: parent.bottom
              right: parent.right
              margins: 12
            }
            width: 44
            height: 44
            radius: 6
            color: "#61afef"
            visible: !search.searching && card.index < root.shortcuts.length

            Text {
              anchors.centerIn: parent
              text: root.shortcuts.charAt(card.index).toUpperCase()
              color: "#24272e"
              font {
                family: "Noto Sans Mono"
                pixelSize: 28
                bold: true
              }
            }
          }
        }

        Text {
          anchors.centerIn: parent
          visible: grid.count === 0
          text: "No matching windows"
          color: "#abb2bf"
          font.pixelSize: 22
        }
      }
    }
  }
}
