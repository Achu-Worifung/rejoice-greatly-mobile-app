package com.rejoicegreatly.app

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity (a FlutterActivity subclass) shares its Flutter engine
// with the background audio service, so sermon playback survives the activity
// being backgrounded and a tap on the media notification comes back here.
class MainActivity : AudioServiceActivity()
