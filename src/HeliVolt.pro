QT += qml quick quickcontrols2 multimedia

CONFIG += c++14 qtquickcompiler

SOURCES += cpp/main.cpp
HEADERS += cpp/platform.h

RESOURCES += resources.qrc

RESOURCES += qml/qml.qrc

RESOURCES += fonts/fonts.qrc
RESOURCES += assets/assets.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

macx {
    QMAKE_INFO_PLIST = osx/Info.plist
}

ios {
    QMAKE_INFO_PLIST = ios/Info.plist
}

android-g++ {
    QT += androidextras
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

    DISTFILES += \
        android/AndroidManifest.xml \
        android/res/values/libs.xml
}

CONFIG(debug, debug|release) {
    message("debug mode")
    DEFINES += DEBUG
} else
{
    message("release mode")
}
