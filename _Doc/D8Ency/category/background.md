### Line
#### Modifier
- line modifier are stored inside the `encyclopedia` parameter
- Wave
 - give a wave effect to the line, must be a array
 -  {
        "wave" : {
            "lockStart" : false, // lock the startPos of the first segment in place (optional)
            "lockEnd" : false, // lock the endPos of the last segment in place (optional)
            "startStrenght" : 0, // how much the first segment startPos isn't affected (optional)
            "endStrenght" : 0, // how much the last segment endPos isn't affected (optional)

            "endColor" : [0, 0, 255, 255], (optional)
            "segmentCount" : 12, // set the number of segment (optional)
            "speed" : 6, // prettymuch amplitude (optional)
            "range" : 3 // how far does it wave (optional)
        }
    }