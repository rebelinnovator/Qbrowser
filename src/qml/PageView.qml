/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the QtBrowser project.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see http://www.qt.io/terms-conditions. For further
** information use the contact form at http://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPLv2 included in the
** packaging of this file. Please review the following information to
** ensure the GNU General Public License version 2 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file. Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0
import QtWebEngine 1.3
import QtWebEngine.experimental 1.0
import QtQuick.Controls 1.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

Rectangle {
    id: root
    property int animationDuration: 200
    property int itemWidth: root.width / 2
    property int itemHeight: root.height / 2 - toolBarHeight

    property int viewWidth: root.width - (2 * 50)

    property bool interactive: true

    property string background: "#62b0e0"

    property alias currentIndex: pathView.currentIndex
    property alias count: pathView.count

    property string viewState: "page"

    property QtObject otrProfile: WebEngineProfile {
        offTheRecord: true
    }

    property QtObject defaultProfile: WebEngineProfile {
        storageName: "YABProfile"
        offTheRecord: false
    }

    Component {
        id: tabComponent
        Item {
            id: tabItem
            property alias webView: webEngineView
            property alias title: webEngineView.title

            property var image: QtObject {
                property string imageUrl: "qrc:///about"
                property string url: "about:blank"
            }

            visible: opacity != 0.0

            Behavior on opacity {
                NumberAnimation { duration: animationDuration / 4; easing.type: Easing.InQuad}
            }

            anchors.fill: parent

            Action {
                shortcut: "Ctrl+F"
                onTriggered: {
                    findBar.visible = !findBar.visible
                    if (findBar.visible) {
                        findTextField.forceActiveFocus()
                    }
                }
            }
            FeaturePermissionBar {
                id: permBar
                view: webEngineView
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                z: 3
            }

            WebEngineView {
                id: webEngineView

                anchors {
                    fill: parent
                    top: permBar.bottom
                }

                profile: defaultProfile

                function takeSnapshot() {
                    console.log("takeSnapshot")
                    if (tabItem.image.url == webEngineView.url || tabItem.opacity != 1.0)
                        return

                    tabItem.image.url = webEngineView.url
                    blur.grabToImage(function(result) {
                        tabItem.image.imageUrl = result.url;
                        console.log("takeSnapshot("+result.url+")")
                    });
                }

/*
                settings.autoLoadImages: appSettings.autoLoadImages
                settings.javascriptEnabled: appSettings.javaScriptEnabled
                settings.errorPageEnabled: appSettings.errorPageEnabled
                settings.pluginsEnabled: appSettings.pluginsEnabled
*/
                onCertificateError: {
                    if (!acceptedCertificates.shouldAutoAccept(error)){
                        error.defer()
                        sslDialog.enqueue(error)
                    } else{
                        error.ignoreCertificateError()
                    }
                }

                onNewViewRequested: {
                    var tab
                    if (!request.userInitiated)
                        print("Warning: Blocked a popup window.")
                    else if (request.destination == WebEngineView.NewViewInTab) {
                        tab = tabs.createEmptyTab()
                        pathView.positionViewAtIndex(tabs.count - 1, PathView.SnapPosition)
                        request.openIn(tab.webView)
                    } else if (request.destination == WebEngineView.NewViewInBackgroundTab) {
                        tab = tabs.createEmptyTab()
                        request.openIn(tab.webView)
                    } else if (request.destination == WebEngineView.NewViewInDialog) {
                        var dialog = tabs.createEmptyTab()
                        request.openIn(dialog.webView)
                    } else {
                        var window = tabs.createEmptyTab()
                        request.openIn(window.webView)
                    }
                }

                onFeaturePermissionRequested: {
                    permBar.securityOrigin = securityOrigin;
                    permBar.requestedFeature = feature;
                    permBar.visible = true;
                }
            }

            Desaturate {
                id: desaturate
                visible: desaturation != 0.0
                anchors.fill: webEngineView
                source: webEngineView
                desaturation: root.interactive ? 0.0 : 1.0

                Behavior on desaturation {
                    NumberAnimation { duration: animationDuration }
                }
            }

            FastBlur {
                id: blur
                visible: radius != 0.0
                anchors.fill: desaturate
                source: desaturate
                radius: desaturate.desaturation * 25
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.interactive

                onWheel: wheel.accepted = true
            }

            Rectangle {
                id: findBar
                anchors.top: webEngineView.top
                anchors.right: webEngineView.right
                width: 240
                height: 35
                border.color: "lightgray"
                border.width: 1
                radius: 5
                visible: false
                color: "gray"

                RowLayout {
                    anchors.centerIn: findBar
                    TextField {
                        id: findTextField
                        onAccepted: {
                            webEngineView.findText(text)
                        }
                    }
                    ToolButton {
                        id: findBackwardButton
                        iconSource: "qrc:///previous"
                        onClicked: webEngineView.findText(findTextField.text, WebEngineView.FindBackward)
                    }
                    ToolButton {
                        id: findForwardButton
                        iconSource: "qrc:///next"
                        onClicked: webEngineView.findText(findTextField.text)
                    }
                    ToolButton {
                        id: findCancelButton
                        iconSource: "qrc:///stop"
                        onClicked: findBar.visible = false
                    }
                }
            }
        }
    }

    ListModel {
        id: listModel
    }

    function createEmptyTab() {
        var tab = add(tabComponent)
        return tab
    }

    function add(component) {
        var element = {"item": null }
        element.item = component.createObject(root, { "width": root.width, "height": root.height })

        if (element.item == null) {
            console.log("PageView::add(): Error creating object");
            return
        }
        element.item.webView.url = "about:blank"
        listModel.append(element)

        pathView.positionViewAtIndex(listModel.count - 1, PathView.SnapPosition)

        return element.item
    }

    function remove(index) {
        pathView.interactive = false
        pathView.currentItem.visibility = 0.0
        listModel.remove(index)
        pathView.interactive = true
        if (listModel.count == 0)
            engine.rootWindow.close()
    }

    function get(index) {
        return listModel.get(index)
    }

    Component {
        id: delegate

        Rectangle {
            id: wrapper

            property real visibility: 0.0
            property bool isCurrentItem: PathView.isCurrentItem

            visible: visibility != 0.0
            state: isCurrentItem ? root.viewState : "list"

            states: [
                State {
                    name: "page"
                    PropertyChanges { target: wrapper; width: root.width; height: root.height; visibility: 0.0 }
                    PropertyChanges { target: pathView; interactive: false }
                    PropertyChanges { target: item; opacity: 1.0; visible: visibility < 0.1; z: 5 }
                },
                State {
                    name: "list"
                    PropertyChanges { target: wrapper; width: itemWidth; height: itemHeight; visibility: 1.0 }
                    PropertyChanges { target: pathView; interactive: !pathView.fewTabs }
                    PropertyChanges { target: item; opacity: 0.0; visible: opacity != 0.0 }
                }
            ]

            transitions: Transition {
                ParallelAnimation {
                    PropertyAnimation { property: "visibility"; duration: animationDuration }
                    PropertyAnimation { properties: "x,y"; duration: animationDuration }
                    PropertyAnimation { properties: "width,height"; duration: animationDuration}
                }
            }

            width: itemWidth; height: itemHeight
            scale: pathView.moving ? 0.65 : PathView.itemScale
            z: Math.round(PathView.itemZ)

            function indexForPosition(x, y) {
                var pos = pathView.mapFromItem(wrapper, x, y)
                return pathView.indexAt(pos.x, pos.y)
            }

            function itemForPosition(x, y) {
                var pos = pathView.mapFromItem(wrapper, x, y)
                return pathView.itemAt(pos.x, pos.y)
            }

            MouseArea {
                anchors.fill: wrapper
                onClicked: {
                    mouse.accepted = true
                    console.log("z= " + z)
                    var index = indexForPosition(mouse.x, mouse.y)
                    var distance = Math.abs(pathView.currentIndex - index)

                    if (index < 0)
                        return

                    if (index == pathView.currentIndex) {
                        if (root.viewState == "list")
                            root.viewState = "page"
                        return
                    }

                    if (pathView.currentIndex == 0 && index === pathView.count - 1) {
                        pathView.decrementCurrentIndex()
                        return
                    }

                    if (pathView.currentIndex == pathView.count - 1 && index == 0) {
                        pathView.incrementCurrentIndex()
                        return
                    }

                    if (distance > 1) {
                        pathView.positionViewAtIndex(index, PathView.SnapPosition)
                        return
                    }

                    if (pathView.currentIndex > index) {
                        pathView.decrementCurrentIndex()
                        return
                    }

                    if (pathView.currentIndex < index) {
                        pathView.incrementCurrentIndex()
                        return
                    }
                }
            }

            Rectangle {
                color: background

                DropShadow {
                    visible: wrapper.visibility == 1.0
                    anchors.fill: snapshot
                    radius: 50
                    verticalOffset: 5
                    horizontalOffset: 0
                    samples: radius * 2
                    color: Qt.rgba(0, 0, 0, 0.5)
                    source: snapshot
                }

                Image {
                    id: snapshot
                    smooth: true
                    source: item.image.imageUrl
                    anchors.fill: parent
                    Rectangle {
                        opacity: wrapper.isCurrentItem && !pathView.moving && !pathView.flicking ? 1.0 : 0.0
                        visible: opacity != 0.0
                        width: 45
                        height: 45
                        radius: width / 2
                        color: closeButton.pressed ? buttonHighlightColor : "white"
                        border.width: 1
                        border.color: "black"
                        anchors {
                            horizontalCenter: parent.right
                            verticalCenter: parent.top
                        }
                        Image {
                            anchors.fill: parent
                            source: "qrc:///close"
                            MouseArea {
                                id: closeButton
                                anchors.fill: parent
                                onClicked: {
                                    var index = indexForPosition(mouse.x, mouse.y)
                                    itemForPosition(mouse.x, mouse.y).visible = false
                                    remove(index)
                                }
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: animationDuration }
                        }
                    }
                }

                anchors.fill: wrapper
            }

            Text {
                anchors {
                    top: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                elide: Text.ElideRight
                text: item.title
                font.pointSize: 10
                font.family: "Monospace"
                color: "#464749"
                visible: wrapper.isCurrentItem
            }
            Behavior on scale {
                NumberAnimation { duration: animationDuration }
            }
        }
    }

    PathView {
        id: pathView
        pathItemCount: 5
        anchors.fill: parent
        model: listModel
        delegate: delegate
        highlightMoveDuration: animationDuration
        flickDeceleration: animationDuration / 2
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5

        dragMargin: itemHeight

        snapMode: PathView.SnapToItem

        property bool fewTabs: count < 3
        property int margin: {
            if (fewTabs)
                return viewWidth / 4
            if (count == 4)
                return 2 * toolBarHeight
            return toolBarHeight
        }

        focus: interactive

        Rectangle {
            color: background
            anchors.fill: parent
        }

        path: Path {
            id: path
            startX: pathView.margin ; startY: root.height / 2
            PathAttribute { name: "itemScale"; value: pathView.fewTabs ? 0.4 : 0.2 }
            PathAttribute { name: "itemZ"; value: 0 }
            PathLine { relativeX: viewWidth / 6 ; y: root.height / 2 }
            PathAttribute { name: "itemScale"; value: 0.4 }
            PathAttribute { name: "itemZ"; value: 3 }
            PathLine { x: viewWidth / 2; y: root.height / 2 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemZ"; value: 6 }
            PathLine { x: root.width - pathView.margin - viewWidth / 6; y: root.height / 2 }
            PathAttribute { name: "itemScale"; value: 0.5 }
            PathAttribute { name: "itemZ"; value: 4 }
            PathLine { x: root.width - pathView.margin; y: root.height / 2 }
            PathAttribute { name: "itemScale"; value: pathView.fewTabs ? 0.5 : 0.1 }
            PathAttribute { name: "itemZ"; value: 2 }
        }

        Keys.onLeftPressed: decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()
    }
}
