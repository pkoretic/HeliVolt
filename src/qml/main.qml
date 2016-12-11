import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1
import QtMultimedia 5.7

import "../icons"
import "components"

Image
{
    id: main

    source: "../assets/background.png"

    property var pages: []

    property bool game_started: false
    property bool dropping: true

    property int tiles_in_page: 8
    property int tile_width: (width / tiles_in_page + 1) |0

    property int distance: 0

    // initialization
    Component.onCompleted:
    {
        if(pages[0])
            pages[0].destroy()

        if(pages[1])
            pages[1].destroy()

        pages[0] = null
        pages[1] = renderPage(0, main.width |0)
    }

    // return random number in range
    function makeRandom(min, max)
    {
        return (Math.random() * (max - min) + min) |0
    }

    // main render page function
    function renderPage(from, to)
    {
        var main_height = main.height |0
        var min_height = main_height * 0.1 |0
        var max_height = main_height  * 0.2 |0

        var pageRect = pageComponent.createObject(main, { x: from, width: to, height: main_height } )

        for(var i = tiles_in_page; i--;)
        {
            var h = makeRandom(min_height, max_height)

            var x = tile_width * i
            tile1Component.createObject(pageRect, { height: h, width: tile_width, x: x })
            tile2Component.createObject(pageRect, { height: h, width: tile_width,  x: x, y: main_height - h })
        }

        if(pages[0])
            wallComponent.createObject(pageRect, { height: main_height * 0.25, width: tile_width / 2, x: tile_width, y: makeRandom(max_height, main_height - max_height * 2) })

        return pageRect
    }

    // background music
    Audio
    {
        source: "../assets/music.mp3"
        loops: Audio.Infinite
        autoPlay: true
    }

    Audio
    {
        id: effect_hit
        source: "../assets/hit.wav"
    }

    //! player
    Item
    {
        id: player

        x: (parent.width * 0.2) |0
        y: (parent.height / 2 - height / 2) |0

        height: childrenRect.height
        width: childrenRect.width |0

        Behavior on y { enabled: game_started; SmoothedAnimation { id: upDownAnimation }}

        // simple collision detection
        onYChanged:
        {
            if(!game_started)
                return

            page_loop:
            for(var i = pages.length; --i;)
            {
                var page = pages[i]
                if(!page)
                    continue

                var children = page.children
                for(var c = children.length; --c;)
                {
                    var child = children[c]
                    var cords = child.mapToItem(main, 0, 0)
                    if(cords.x > player.x && cords.x < player.x + player.width && cords.y + child.height >= player.y && cords.y < player.y + height)
                    {
                        game_started = false
                        effect_hit.play()

                        if(distance > _settings.best_score)
                            _settings.best_score = distance

                        loader.reload()
                        break page_loop
                    }
                }
            }
        }

        function drop ()
        {
            if(dropping && !game_started)
                return

            animation.duration = 100
            animation.restart()
            dropping = true
            upDownAnimation.duration = 1000
            y = main.height |0
        }

        function rise ()
        {
            if(!dropping)
                return

            animation.duration = 500
            animation.restart()
            dropping = false
            upDownAnimation.duration = 1600
            y = 0
        }

        Image
        {
            id: head
            height: main.height * 0.1 |0
            width: height
            source: "../assets/bot_%1_right.png".arg(dropping ? "blink" : "eyes")
            z: 1
        }

        Image
        {
            height: main.height * 0.1 |0
            width: height
            y: height / 3
            source: "../assets/bot_ball.png"

            RotationAnimator on rotation
            {
                id: animation

                from: 0
                to: 360
                loops: Animation.Infinite
            }
        }
    }

    //! overlay information
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

    //! tile1 component
    Component
    {
        id: tile1Component
        Image
        {
            source: "../assets/tile1.png"
        }
    }

    //! tile2 component
    Component
    {
        id: tile2Component
        Image
        {
            source: "../assets/tile2.png"
        }
    }

    //! wall component
    Component
    {
        id: wallComponent
        Image
        {
            source: "../assets/tile3.png"
        }
    }

    // page holder
    Component
    {
        id: pageComponent
        Item
        {
            Behavior on x { enabled: game_started; NumberAnimation {  duration: 3000 } }
            onXChanged: ++distance
        }
    }

    // main "level" drawing loop
    Timer
    {
        interval: 1500
        running: game_started
        repeat: true
        triggeredOnStart: true

        onTriggered:
        {
            // destroy page that passed
            if(pages[0])
                pages[0].destroy()

            // swap pages for new position
            pages[0] = pages[1]
            pages[1] = renderPage(main.width |0, main.width * 2 |0)

            // triger pages animation
            pages[0].x = -main.width * 2 |0
            pages[1].x = -main.width |0
        }
    }

    // keyboard play
    Keys.onPressed:
    {
        if(!game_started)
            game_started = true

        player.rise()

        event.accepted = true
    }

    Keys.onReleased: player.drop()

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

    // overlay information
    Item
    {
        anchors.fill: parent
        visible: !game_started
        Text
        {
            id: topInstructionText
            color: "#3fcdfd"
            font.pixelSize: 26
            font.family: "Digital-7"
            text: "TAP OR PRESS ANY KEY TO START"
            anchors.centerIn: parent
        }

        Text
        {
            color: "#44fffe"
            font.pixelSize: 20
            font.family: "Digital-7"
            text: "TAP/PRESS KEY AND HOLD TO GO UP\nRELEASE TO GO DOWN"
            anchors.top: topInstructionText.bottom
            anchors.topMargin: height
            anchors.right: topInstructionText.right
        }
    }
}
