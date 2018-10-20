import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtMultimedia 5.11

Item
{
    id: main

    enabled: false

    property var pages: []
    property var objects: []

    property bool game_started: false
    property bool dropping: true

    property int tiles_in_page: 8
    property int tile_width: (width / tiles_in_page)
    property int wall_height: (main.height * 0.25)
    property int wall_width: tile_width  / 2

    property int distance: 0

    Component.onCompleted: enabled = true

    // return random number in range
    function makeRandom(min, max)
    {
        return (Math.random() * (max - min) + min)
    }

    // main render function
    // renders one item at a time
    function renderPage()
    {
        var min_height = main.height * 0.1
        var max_height = main.height * 0.2

        var h = makeRandom(min_height, max_height)

        // draw top and botom tile
        var tile1 = topTileComponent.createObject(main, { x: main.width, width: tile_width, height: h })
        var tile2 = bottomTileComponent.createObject(main, { x: main.width, width: tile_width, height: h, y: main.height - h })

        // draw wall once a "page"
        var wall
        if(distance % 100 === 0)
            wall = wallComponent.createObject(main, { height: wall_height, width: wall_width, x: main.width, y: makeRandom(max_height, main.height - max_height * 2) })

        // check for collision detection and destroy past objects
        for(var i = 0; i < objects.length; i++)
        {
            var object = objects[i]

            if (object.x < player.x + player.width && object.x + object.width > player.x && object.y < player.y + player.height && object.height + object.y > player.y)
            {
                if(distance > _settings.best_score)
                    _settings.best_score = distance

                loader.reload()
                break
            }

            if(object.x === -tile_width)
            {
                object.destroy()
                objects.splice(i, 1)
                continue
            }
        }

        // save new objects
        objects.push(tile1)
        objects.push(tile2)
        if(wall) objects.push(wall)


        // incrase distance
        distance += 10
    }

    // background music
    Audio
    {
        id: music
        source: "../assets/music.mp3"
        loops: Audio.Infinite
        autoPlay: true
    }

    // player
    Item
    {
        id: player

        x: (parent.width * 0.2)
        y: (parent.height / 2 - height / 2)

        height: childrenRect.height
        width: childrenRect.width

        Behavior on y { SmoothedAnimation { id: upDownAnimation }}

        function drop ()
        {
            if(dropping)
                return

            dropping = true

            rotator.duration = 100
            rotator.restart()
            upDownAnimation.duration = 1000
            y = main.height - height
        }

        function rise ()
        {
            if(!dropping)
                return

            dropping = false

            rotator.duration = 500
            rotator.restart()
            upDownAnimation.duration = 1600
            y = 0
        }

        Image
        {
            id: head
            height: main.height * 0.1
            width: height
            source: "../assets/bot_%1_right.png".arg(dropping ? "blink" : "eyes")
            z: 1
        }

        Image
        {
            height: main.height * 0.1
            width: height
            y: height / 3
            source: "../assets/bot_ball.png"

            RotationAnimator on rotation
            {
                id: rotator

                from: 0
                to: 360
                loops: Animation.Infinite
            }
        }
    }

    // overlay game information
    Item
    {
        width: parent.width - x * 2
        height: childrenRect.height
        x: 15
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        z: 1

        Row
        {
            width: childrenRect.width
            height: childrenRect.height

            Text
            {
                color: "#ffffff"
                font.pixelSize: 24
                font.bold: true
                style: Text.Outline
                text: "distance: "
            }

            Text
            {
                font.pixelSize: 24
                color: "#ffffff"
                font.bold: true
                style: Text.Outline
                text: distance
                textFormat: Text.PlainText
            }
        }

        Row
        {
            anchors.right: parent.right
            width: childrenRect.width
            height: childrenRect.height

            Text
            {
                color: "#ffffff"
                font.pixelSize: 24
                font.bold: true
                style: Text.Outline
                text: "best: "
            }

            Text
            {
                font.pixelSize: 24
                color: "#ffffff"
                font.bold: true
                style: Text.Outline
                text: _settings.best_score
            }
        }
    }

    // top tile component
    Component
    {
        id: topTileComponent
        Image
        {
            source: "../assets/top_tile.png"
            NumberAnimation on x { duration : 1800; to: -tile_width }
        }
    }

    // tile2 component
    Component
    {
        id: bottomTileComponent
        Image
        {
            source: "../assets/bottom_tile.png"
            NumberAnimation on x { duration : 1800; to: -tile_width }
        }
    }

    // wall component
    Component
    {
        id: wallComponent
        Image
        {
            source: "../assets/wall_tile.png"
            NumberAnimation on x { duration : 1800; to: -tile_width }
        }
    }

    // main "level" drawing loop
    Timer
    {
        interval: 180
        running: game_started
        repeat: true
        triggeredOnStart: true

        onTriggered: renderPage()
    }

    // keyboard play
    Keys.onPressed:
    {
        if(event.key !== Qt.Key_Space)
            return

        if(!game_started)
            game_started = true

        player.rise()

        event.accepted = true
    }

    Keys.onReleased:
    {
        if(event.key === Qt.Key_Space)
        {
            player.drop()
            event.accepted = true
        }
    }

    // mouse/tap play
    MouseArea
    {
        id: mouse_area
        anchors.fill: parent
        onPressed:
        {
            if(!game_started)
                game_started = true

            player.rise()
        }

        onReleased: player.drop()
    }

    // overlay instructions
    Column
    {
        visible: !game_started
        height: childrenRect.height
        width: childrenRect.width
        anchors.left: player.right
        anchors.leftMargin: 20
        anchors.verticalCenter: player.verticalCenter
        spacing: 5

        Text
        {
            id: topInstructionText
            color: "#3fcdfd"
            font.pixelSize: 26
            font.family: "Digital-7"
            text: "TAP OR PRESS SPACE TO START"
        }

        Text
        {
            color: "#44fffe"
            font.pixelSize: 20
            font.family: "Digital-7"
            text: "TAP/PRESS SPACE AND HOLD TO GO UP\nRELEASE TO GO DOWN"
            anchors.right: topInstructionText.right
            lineHeight: 1.1
        }
    }

    // stop music and reload game if gone to background
    Connections
    {
        target: Qt.application
        onStateChanged:
        {
            if(Qt.application.state === Qt.ApplicationActive)
                loader.reload()
            else
                music.stop()
        }
    }
}
