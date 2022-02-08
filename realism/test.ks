runOncePath("./launch.ks").

SET V0 TO GetVoice(0).
V0:PLAY( NOTE( 440, 1) ).  // Play one note at 440 Hz for 1 second.

// Play a 'song' consisting of note, note, rest, sliding note, rest:
V0:PLAY(
    LIST(
        NOTE("A#4", 0.2,  0.25), // quarter note, of which the last 0.05s is 'release'.
        NOTE("A4",  0.2,  0.25), // quarter note, of which the last 0.05s is 'release'.
        NOTE("R",   0.2,  0.25), // rest
        SLIDENOTE("C5", "F5", 0.45, 0.5), // half note that slides from C5 to F5 as it goes.
        NOTE("R",   0.2,  0.25)  // rest.
    )
).
V0:play(
    LIST( // rhythm line
    SLIDENOTE("C2", "A1", 0.2),
    SLIDENOTE("E3", "C3", 0.2),
    SLIDENOTE("C2", "A1", 0.2),
    SLIDENOTE("E3", "C3", 0.2),
    SLIDENOTE("C2", "A1", 0.2),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    SLIDENOTE("E3", "C3", 0.2),
    SLIDENOTE("C2", "A1", 0.2),
    SLIDENOTE("E3", "C3", 0.2),
    SLIDENOTE("C2", "A1", 0.2),
    SLIDENOTE("E3", "C3", 0.2),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.05),
    NOTE("E3", 0.05),
    NOTE("E3", 0.05),
    NOTE("E3", 0.05),
    NOTE("E3", 0.05),
    NOTE("C2", 0.05),
    NOTE("C2", 0.2)
    )
).

launch().