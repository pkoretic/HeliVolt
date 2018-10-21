import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtQuick.Window 2.11
import Qt.labs.settings 1.0

import "../config.js" as Config

ApplicationWindow
{
    id: window

    visible: true
    title: qsTr("HeliVolt")

    width: 800
    height: 600

    color: "#000000"

    visibility: Window.FullScreen

    // this is set from main.cpp
    property bool _DEBUG_MODE

    Component.onCompleted:
    {
        if (_DEBUG_MODE)
            console.log("DEBUG MODE")

        console.log("config:", JSON.stringify(Config, null, 4))
    }

    // persistent settings
    Settings
    {
        id: _settings

        property int best_score: 0
    }

    // digital font
    FontLoader { source: "/fonts/digital-7.ttf"  }

    // background image, always the same
    Image
    {
        anchors.fill: parent
        source: "../assets/background.png"
    }

    // main application content
    // in debug mode fetched from http, in production, builtin version is used
    Loader
    {
        id: loader
        source: _DEBUG_MODE ? "%1/qml/main.qml".arg(Config.api.url) : "qrc:/qml/main.qml"
        anchors.fill: parent
        asynchronous: true
        focus: true

        function reload()
        {
            if (loader.status === Loader.Loading)
                return console.log("Ignoring reload request, reload in progress")

            console.log("application reload")

            var src = source
            source = ""
            __platform.clearCache()
            source = src
        }

        onLoaded: loader.item.forceActiveFocus()
    }

    Label
    {
       id: errorMessage
       color: "white"
       text: "Unable to load remote qml, check if server is available and running"
       width: 300
       wrapMode: Label.WordWrap
       anchors.centerIn: parent
       enabled: _DEBUG_MODE && loader.status === Loader.Error
       visible: enabled

    }

    Button
    {
        anchors.top: errorMessage.bottom
        anchors.topMargin: height
        anchors.horizontalCenter: errorMessage.horizontalCenter
        text: "Retry"
        onClicked: loader.reload()
        enabled: errorMessage.enabled
        visible: enabled
    }
}
