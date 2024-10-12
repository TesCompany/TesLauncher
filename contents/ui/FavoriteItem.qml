/*****************************************************************************
 *   Copyright (C) 2022 by Friedrich Schriewer <friedrich.schriewer@gmx.net> *
 *                                                                           *
 *   This program is free software; you can redistribute it and/or modify    *
 *   it under the terms of the GNU General Public License as published by    *
 *   the Free Software Foundation; either version 2 of the License, or       *
 *   (at your option) any later version.                                     *
 *                                                                           *
 *   This program is distributed in the hope that it will be useful,         *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 *   GNU General Public License for more details.                            *
 *                                                                           *
 *   You should have received a copy of the GNU General Public License       *
 *   along with this program; if not, write to the                           *
 *   Free Software Foundation, Inc.,                                         *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .          *
 ****************************************************************************/
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0
import QtQuick.Window 2.2
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.kirigami 2.13 as Kirigami
import QtQuick.Controls 2.15

import "../code/tools.js" as Tools

Item {
  id: favItem

  property int iconSize: units.gridUnit * 3.2

  width: 112
  height: iconSize + units.smallSpacing + appname.implicitHeight + 10

  signal itemActivated(int index, string actionId, string argument)

  property bool highlighted: false
  property bool isDraging: false

  property bool hasActionList: ((model.favoriteId !== null)
      || (("hasActionList" in model) && (model.hasActionList === true)))

  property int itemIndex: model.index

  property var triggerModel


  function openActionMenu(x, y) {
      var actionList = hasActionList ? model.actionList : [];
      console.log(model.favoriteId)
      Tools.fillActionMenu(i18n, actionMenu, actionList, globalFavorites, model.favoriteId);
      actionMenu.visualParent = favItem;
      actionMenu.open(x, y);
  }

  function actionTriggered(actionId, actionArgument) {
      var close = (Tools.triggerAction(triggerModel, index, actionId, actionArgument) === true);
      if (close) {
          root.toggle();
      }
  }

  PlasmaCore.IconItem {
    id: appicon
    anchors {
      top: parent.top
      horizontalCenter: parent.horizontalCenter
    }
    width: iconSize
    height: iconSize
    source: model.decoration
  }

  PlasmaComponents.Label {
    id: appname
    text: ("name" in model ? model.name : model.display)
    font.family: main.textFont
    font.pointSize: main.textSize
    anchors {
      top: appicon.bottom
      topMargin: units.smallSpacing
      left: parent.left
      right: parent.right
    }
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignTop
    wrapMode: Text.WordWrap
  }
  
  Rectangle {
    id: highlightItem
    visible: !plasmoid.configuration.enableGlow
    height: parent.height
    width: parent.width 
    radius: 8
    z: -20
    color: "transparent"
    clip: true
    anchors.centerIn: parent
    // apply rounded corners mask
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            x: highlightItem.x; y: highlightItem.y
            width: highlightItem.width
            height: highlightItem.height
            radius: highlightItem.radius
        }
    }

    PlasmaExtras.Highlight {
      id: rect
      visible: !plasmoid.configuration.enableGlow
      width: highlightItem.width + 15
      height: highlightItem.height + 15
      
      anchors.centerIn: parent
      
      states: [
        State {
          name: "highlight"; when: (highlighted)
          PropertyChanges { target: rect; hovered: true}
          PropertyChanges { target: rect; opacity: 1}
        },
        State {
          name: "default"; when: (!highlighted)
          PropertyChanges { target: rect; hovered: false}
          PropertyChanges { target: rect; opacity: 0}
        }
      ]
      transitions: highlight
    }
  }

  DropShadow {
    id:appIconGlow
    visible: plasmoid.configuration.enableGlow
    anchors.fill: appicon
    cached: true
    horizontalOffset: 0
    verticalOffset: 0
    radius: 15.0
    samples: 16
    color: main.glowColor1
    source: appicon
    states: [
      State {
        name: "highlight"; when: (highlighted)
        PropertyChanges { target: appIconGlow; opacity: 1}
         PropertyChanges { target: appNameGlow; opacity: 1}
      },
      State {
        name: "default"; when: (!highlighted)
        PropertyChanges { target: appIconGlow; opacity: 0}
        PropertyChanges { target: appNameGlow; opacity: 0}
      }
    ]
    transitions: highlight
  }

  DropShadow {
    id: appNameGlow
    visible: plasmoid.configuration.enableGlow
    anchors.fill: appname
    cached: true
    horizontalOffset: 0
    verticalOffset: 0
    radius: 15.0
    samples: 16
    color: main.glowColor1
    source: appname
  }
  
  MouseArea {
      id: ma
      anchors.fill: parent
      z: parent.z + 1
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      hoverEnabled: true
      onClicked: {
        if (!isDraging) {
          if (mouse.button == Qt.RightButton ) {
            if (favItem.hasActionList) {
                var mapped = mapToItem(favItem, mouse.x, mouse.y);
                openActionMenu(mapped.x, mapped.y);
            }
          } else {
            triggerModel.trigger(index, "", null);
            root.toggle()
          }
        }
      }
      onReleased: {
        isDraging: false
      }
      onEntered: {
        if(plasmoid.configuration.enableGlow) {
          appIconGlow.state = "highlight"
        } else { rect.state = "highlight" }
        
      }
      onExited: {
        if(plasmoid.configuration.enableGlow) {
          appIconGlow.state = "default"
        } else { rect.state = "default" }
      }
      onPositionChanged: {
        isDraging = pressed
        if (pressed){
          if ("pluginName" in model) {
            dragHelper.startDrag(kicker, model.url, model.decoration,
                "text/x-plasmoidservicename", model.pluginName);
          } else {
            kicker.dragSource = favItem;
            dragHelper.startDrag(kicker, model.url, model.decoration);
          }
        }
      }
  }
  ActionMenu {
      id: actionMenu

      onActionClicked: {
          visualParent.actionTriggered(actionId, actionArgument);
          root.toggle()
      }
  }
  Transition {
    id: highlight
    ColorAnimation {duration: 100 }
  }
}
