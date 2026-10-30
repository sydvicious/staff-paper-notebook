<!-- Copyright @2026 Syd Polk. All Rights Reserved -->
<!-- SPDX-License-Identifier: BSD-3-Clause -->

# Summary

Staff Paper Notebook is an iPhone and iPad app for writing music by hand on staff paper, with an Apple Pencil or a finger. It learns how you draw each symbol and turns your ink into notation you can fix, play back and export.

# Rationale

Notation programs make you enter music with a mouse and palettes, which is slow and nothing like writing on paper. A recognizer trained on your own handwriting can be accurate with only a few samples of each symbol, because it only has to learn one person's hand. The Pencil's squeeze, hover and pressure, plus phones with bigger screens, make the device a real notebook. Playback, MusicXML and MIDI then take this from a sketchpad toward a real notation program.

# Phases

- **Phase 0: project and release machinery.** The Xcode project and the house release flow, before any feature work.
  - SwiftUI app for iPhone and iPad, with a deployment target of iOS 27.
  - Swift 6 language mode, complete strict concurrency, and the Main Actor as the default isolation.
  - `Version.xcconfig`, `CHANGELOG.md`, the bump script.
  - A release test script that runs on Claude's iPhone and iPad simulators on iOS 27.
  - A release script that checks for a clean main and a `CHANGELOG.md` heading, runs every test, and tags. No DMG, and no upload until App Store Connect is set up.
- **Phase 1: score model and engraving.** The data the ink gets translated into, drawn on a single staff with Bravura.
  - The model is score → staff → measure → events.
  - Pitch math, with clef and key context.
  - Checks on how full each measure is.
  - Export to MusicXML.
- **Phase 2: ink and training.** A PencilKit canvas over app-drawn staff paper, and the first-run training flow.
  - Store each training sample as strokes with timing, so a sample can be trained on again later.
  - Train progressively: the core set first, and the rest of the symbols the first time you need them.
- **Phase 3: recognition.** Group strokes into symbols, classify each one, then interpret it against the staff.
  - Pitch comes from where the note sits on the staff; the classifier only names the symbol.
  - Each symbol keeps its ink and its list of the recognizer's next-best guesses.
- **Phase 4: correction.** Press a symbol to select it, drag a note up or down to change its pitch, and squeeze for a menu of alternatives and Delete.
  - Long-press does the same on devices without squeeze, and with a finger.
  - Scribbling over a symbol erases it.
  - Every correction becomes a new training sample.
- **Phase 5: playback.** AVAudioEngine with a General MIDI SoundFont, with dynamics and hairpins mapped to how loud the notes play.
- **Phase 6: multiple staves.** Parts, systems, the grand staff with its brace, and page layout.
  - A flow for adding a staff: choose an instrument, which sets its name, clef, transposition and range.
  - Transposing instruments: each staff shows written pitch, with a switch to show the whole score at concert pitch.
- **Phase 7: chord changes and lyrics.** Handwritten chord symbols above the staff and lyrics below it, recognized and attached to the notes.
  - Chord symbols: root, quality, extensions, alterations and slash bass, played back as chords.
  - Lyrics: syllables attached to notes, with hyphens and extenders.
- **Phase 8: keyboard and MIDI.** Note entry from a hardware keyboard, and MIDI in and out.
  - Hardware-keyboard step entry, to Syd's own note-input design (still to come).
  - Typing letter names for pitches, as an option.
  - MIDI input, note by note and in real time.
  - MIDI output, and MIDI file export.
- **Later:** toward a full notation program.
  - Possibly a Mac app.
  - Rests and other symbols beyond the core set, if they don't land earlier.
  - Tuplets, multiple voices.
  - Percussion notation, guitar tablature, and other instruments' notation.
  - PDF export, MusicXML import, extracting parts.

# Design Decisions

- **Use our own score model, with MusicXML for exchange.** We aren't tied to a library, and Sibelius, Dorico and MuseScore all read MusicXML.
- **Engrave with SMuFL, using Bravura by default.** It's the standard glyph layout, and the fonts can be swapped (Petaluma for the handwritten look).
- **Start the recognizer as few-shot template matching, behind a protocol.** A point-cloud recognizer (the $P/$Q family) works from five or so samples per symbol and needs no ML pipeline. Core ML can replace it later.
- **Pitch is geometry, not recognition.** The app draws the staff, so a notehead's center snaps to a line or space.
- **Recognize in two stages: what the glyph is, then what it means.** Clef, key and time signature give context to the notes that follow, and a measure that doesn't add up flags a likely mistake.
- **Ink is never thrown away.** Keeping it makes the correction menu, re-recognition after more training, and showing the original ink all possible.
- **Every input feeds one undoable edit model.** Pencil, finger, keyboard and MIDI all produce the same edit commands.
- **The canvas is UIKit inside SwiftUI.** PencilKit and `UIPencilInteraction` (squeeze) live in UIKit; everything else is SwiftUI.
- **Each score is a document (`DocumentGroup`), and the training set lives in the app's own storage.** That keeps scores in Files and iCloud Drive, and the training set can move to iCloud sync later.
- **Plans live in `plans/`.** This file is the master plan; each feature gets its own plan beside it.
- **Start in Swift 6, with complete strict concurrency and the Main Actor as the default isolation.** New projects start there.
- **iPhone and iPad only; a release is a tag.** App Store Connect isn't set up yet, so the release script tests and tags, and an `.ipa` is archived by hand when one is wanted.
- **Ink snaps in place, and each measure re-spaces when its bar line is drawn.** It keeps the feel of writing while you write, and looks engraved once a measure is done.
- **"Staff Paper Notebook" is a working name.** It is decided for good before App Store Connect is set up, since the bundle ID can't change after that.

# Background

The repo has only an initial commit: a README, the BSD 3-Clause LICENSE and a .gitignore. The app is inspired by Marco Arment's Fine Liner.

Squeeze needs an Apple Pencil Pro. Pencil 2 has double-tap, and an iPhone has only a finger, so every squeeze action needs a touch equivalent.

The reference release flow, in MarkdownPreviewApp, ends in a notarized Mac DMG. This app is iPhone and iPad only, and App Store Connect isn't set up for it yet, so its release stops at the tests and the tag.

# Detailed discussions

## Releases without App Store Connect

The pieces of the house release flow that carry over unchanged: `Version.xcconfig`, the bump script, the release script's checks (clean main, the release tag not yet taken, a `## <version>` heading in `CHANGELOG.md`), the release test script, and the release tag. What's dropped is everything after the tests that builds and ships a Mac app: the Developer ID export, notarization, the DMG and its layout, and the releases folder.

When App Store Connect is set up, the release script gains an archive and an export with the `app-store-connect` method, and an upload of the build, between the tests and the tag. The bump script already moves the build number for every candidate, which App Store Connect requires.

## Music fonts

**SMuFL** (Standard Music Font Layout) is a standard: every compliant font puts each music glyph at the same code point and ships metadata saying where stems attach, how thick staff lines are, and each glyph's bounding box. Write the engraver against SMuFL once, and any of these fonts drops in. All are under the SIL Open Font License, so they're free to bundle in a commercial app (the license only asks that the font isn't sold by itself and that a modified version is renamed):

- **Bravura** (Steinberg): the reference SMuFL font, with the most complete glyph set. This is the default.
- **Petaluma** (Steinberg): a handwritten "jazz copyist" look. It suits an app built around handwriting, so it could be a style option.
- **Leland** (MuseScore): a traditional engraved look.
- **Leipzig** (Verovio) and **Gootville**: smaller sets, but they show the font can be swapped.

The engraver should read each font's metadata JSON rather than hard-coding positions, so swapping fonts is really just a setting.

## The symbol list has gaps

The first list was: treble clef, bass clef, sharps, flats, key signatures, whole through sixteenth notes, bar lines, crescendos, decrescendos, dynamics, and time signatures.

"Basic music" also needs these:

- **Rests**, whole through sixteenth.
- **Augmentation dots.**
- **Naturals.**
- **Ties and slurs.**
- **Beams.**
- **Ledger lines.**
- **Double and final bar lines.**
- **C and cut-time.**

Repeats, accents and staccato would be good to have early as well. Some things on the list don't need training of their own:

- **Key signatures** are groups of sharps or flats placed right after the clef, so they're recognized from their accidentals and where those sit.
- **Time signatures** are stacked digits, so we train the digits: 2, 3, 4, 5, 6, 7, 8, 9, 1 (for 12) and 6 (for 16).
- **Dynamics** are better trained as whole marks (p, pp, mp, mf, f, ff, sfz, fp) than as single letters, because a written "mf" is one gesture with its own shape.
- **Hairpins** may not need templates at all. Two lines meeting at a point, below the staff, are easy to detect from their shape.

That makes about 35 to 45 symbols at roughly five samples each, which is why training should be progressive. A first session covers the clefs, accidentals, noteheads, stems, flags, bar lines and slurs. Everything else is asked for the first time you need it, or found in Settings.

## How the recognizer works

### Choosing a classifier

A **point-cloud recognizer** ($P, and its faster successor $Q) treats each sample as a set of points. It ignores the order and direction of the strokes, which matters because people draw a sharp's four lines in different orders. It compares a new glyph to each stored template by matching points, and it works from a handful of samples per class with no training step. A new sample is simply added. Its weaknesses: it gets slower as the template set grows (fine at this size), it doesn't handle size and aspect well without normalizing them, and it doesn't know a filled notehead from an open one. For that, we add features: how much of the shape the ink covers, how many strokes it took, and how wide it is against how tall.

**Core ML** with an updatable model (`MLUpdateTask`) could fine-tune on the device. It would need a base model trained on a dataset first (see *Using a pretrained recognizer later*). That is more accuracy for a good deal more work, so it goes behind the same protocol and only if template matching proves too weak.

### Grouping strokes is the hard part

Classifying one glyph is the easy part. Deciding which strokes belong together is harder:

- A quarter note is a filled head plus a stem; an eighth note adds a flag.
- A beam connects several notes, so one stroke belongs to many symbols.
- A sharp drawn quickly can look like two symbols.

The plan is to group strokes first by **timing** (a pause longer than some threshold, tuned during training, closes a group) and **position** (strokes that overlap or touch). The interpretation stage can then split or merge groups when the result doesn't make musical sense. Notes may be better recognized as a notehead plus attachments (stem, flag, dot) than as whole templates, since stem length and direction vary too much for templates to cover.

### Interpreting what was recognized

Once a glyph is named, its place on the staff gives it meaning:

- **Pitch** comes from where the notehead's center falls: a line or space, counting ledger lines, read through the clef, the key signature, and any accidentals earlier in the measure.
- **Context** builds left to right: clef, then key signature, then time signature, then notes.
- **Measure checks:** a measure whose durations don't add up to the time signature is flagged. The likely fix (say, a half note read as a quarter) can be offered first in the correction menu.

## Correcting

- **Selecting.** Press a recognized symbol with the Pencil or a finger. Hover, on iPads that support it, highlights what you're about to select.
- **Moving.** Drag a note up or down and it snaps line by line and space by space, playing the pitch as it moves.
- **The menu.** Squeeze opens a menu at the Pencil tip with the recognizer's next-best guesses and Delete. Long-press opens the same menu where squeeze isn't available. Pencil 2's double-tap could switch between pen and eraser.
- **Erasing.** Scribbling over a symbol deletes it, the way Notes does it.
- **Learning from corrections.** Choosing the right symbol in the menu adds that ink to the training set as a sample of that symbol, so the recognizer keeps getting better. A setting should allow turning this off.

## Ink in place, or reflowed?

Decided: both. Engraved glyphs appear where you drew them, snapped to the staff, which keeps the feel of Fine Liner while you write. When you draw a measure's bar line, the measure re-spaces itself so it looks engraved, with an animation so the move doesn't feel like losing your work.

Things to settle when this is built:
- **Editing a closed measure.** Adding a note to a measure that has already been re-spaced could either re-space it again at once, or leave the new note where it was drawn until the measure is closed again. Re-spacing at once is probably right, since the measure is already engraved.
- **Bar lines drawn out of order.** If a bar line is drawn before the notes in its measure, the measure is closed while still empty. Re-spacing should wait until the measure's durations add up, or re-run each time a note is added.
- **The original ink.** Showing it faintly behind the engraving could be an option.

## Playback

`AVAudioEngine` with an `AVAudioUnitSampler` loaded from a SoundFont. iOS has no built-in General MIDI instruments, so we have to bundle one. FluidR3_GM is MIT-licensed, and GeneralUser GS has its own license we'd need to check. Mapping:

- **Dynamics** set how hard notes are played (MIDI velocity).
- **Hairpins** ramp the volume of the notes they cover (MIDI expression, CC 11), so a held note can swell.
- **Tempo** comes from a marking, or a default.

Playback on a single staff is cheap to build and is also the quickest way to hear what the recognizer thinks you wrote, so it could move up to just after Phase 4.

## Adding a staff

- **Instruments are data.** A bundled list gives each instrument its name and short name, clef or clefs, transposition, range, and General MIDI program for playback. Instruments such as piano, harp and organ add two staves joined by a brace.
- **The flow:** a button below the last staff (and a menu command) opens a searchable list, grouped by family (woodwinds, brass, percussion, keyboards, strings, voices). Choosing one adds its staff or staves. Staves can be reordered by dragging, and deleting one asks first, since its music goes with it.
- **Changing an instrument later** keeps the sounding pitches and rewrites the written ones, so moving a part from Bb clarinet to flute just works.
- **Range:** notes outside the instrument's range are shown in a warning color, the way Sibelius shows them in red.
- **The first staff is just lines.** A new score opens as bare staff lines, like staff paper. The clef, key signature and time signature are drawn, and recognized like everything else.
- **Notes before a clef have no pitch yet.** The model keeps each note's line or space, and gives every note its pitch when a clef is drawn. A clef changed later re-reads them the same way.
- **The first staff has no instrument.** Playback uses piano until one is chosen, and the instrument list can suggest instruments that match the clef that was drawn.
- **iPhone:** there's room for only a few staves. Showing one system at a time, or only the staff being written on, needs working out when this is built.

## Transposing instruments

- **The model stores sounding (concert) pitch.** Each staff's instrument has a transposition, an interval plus any octave, and written pitch is worked out from it. Playback, MIDI and chord analysis then need no conversion. MusicXML stores written pitch with a `<transpose>` element, so its export and import convert.
- **Recognition reads what you wrote in the view you're in.** On a Bb trumpet staff showing written pitch, a note on the third space is read as written C and stored as concert Bb. With concert pitch showing, it's stored as written.
- **Transpose by interval, not by semitones**, so spelling survives: up a major second turns F# into G#, not Ab. Key signatures transpose the same way: a Bb instrument's part for a concert-C piece shows D major. A key that would need more than seven sharps or flats is respelled enharmonically (C# major becomes Db).
- **Concert pitch is a switch for the whole score.** Chord symbols transpose with their staff. Octave transpositions stay as written even at concert pitch; that is the only way they differ from other transpositions.

## Chord changes

- **Where they go:** above the staff, attached to a beat rather than a note, since a chord can change during a held note or a rest.
- **What has to be recognized:** a root (A–G), an accidental, a quality (maj, m or -, °, ø, +, sus, △), extensions (6, 7, 9, 11, 13), alterations (b9, #11, b13) and a slash bass. That's a small grammar over a few dozen glyphs.
- **How:** train the glyphs in the same template recognizer, then parse the sequence against the grammar. The grammar narrows each glyph's candidates (after a root, "m" is likely; "9" won't come first), which helps accuracy. Apple's text recognition (Vision) reads handwritten letters and numbers but not △, ø or °, so it would only cover part of this.
- **How they look:** SMuFL has chord-symbol glyphs, and Petaluma has a handwritten style that suits lead sheets.
- **Playback:** optionally voiced chords on a comping instrument, so a lead sheet sounds like one.
- **Nearby, later:** slash and rhythm notation, which lead sheets often use with chord changes.

## Lyrics

- **Where they go:** below the staff, each syllable attached to the note nearest to where it was written. Hyphens join syllables of a word, and extender lines show a syllable held over several notes.
- **Automatic placement:** syllables go to the notes in order, one each. Rests are skipped, and tied notes count as one note.
- **Dragging a syllable** under the note it belongs to moves it there, and the syllables around it shift to fit.
- **Slurs follow the syllables.** When a syllable spans several notes (a melisma), those notes get a slur. Moving syllables adds, lengthens, shortens or deletes those slurs to match, and stretches the hyphen or extender line after the syllable.
- **Lyric slurs and phrasing slurs are kept apart.** The model records which slurs the lyrics made, and only those change when syllables move. A slur drawn by hand for phrasing is never changed or deleted by a lyric edit.
- **Recognition is open-ended text**, unlike everything else in the app. Vision's handwriting recognition on the ink is the likely tool, and needs testing on short syllables written in a tight space.
- **Typing is probably needed too.** Writing a syllable under every note is slow. A typed path, where Space moves to the next note and a hyphen splits a word as in Sibelius, fits Phase 8's keyboard work. Scribble into a text field gives the Pencil the same path.
- **To investigate: Apple's on-device Foundation Models.**
  - First, whether the framework takes images on iOS 27. If it does, it could read the ink directly, with the surrounding words as context.
  - Text alone still helps. It can correct Vision's readings from the words around them, so "lo-ve" in a line of lyrics comes out as "love".
  - It can split words into syllables as a structured result (`@Generable`), for handwriting and for the typed path. Typed whole words could be split and spread across the notes automatically.
  - The number of notes under a phrase helps it choose between readings.
  - It runs only where Apple Intelligence does, so lyrics have to work without it. Its results go through the same correction menu as everything else.
- **Spacing:** long syllables push notes apart when a measure re-spaces.
- **Later:** more than one verse, and verse numbers.

## Other notation, later

- **Percussion:** a five-line staff with a percussion clef, where each line or space is a different instrument and noteheads vary (x for cymbals). A drum map ties each position to a General MIDI drum note for playback. One-line staves serve single instruments.
- **Guitar tablature:** a six-line staff of fret numbers, so digits drawn on lines are recognized. Tab is usually linked to a standard staff showing the same notes. The tuning comes from the instrument. Chord diagrams (fretboard grids) go with chord symbols.
- **Other instruments' notation:** bowings, fingerings, harmonics, breath marks, harp pedal diagrams. Each is more symbols to train, and some need their own layout.

## Keyboard and MIDI input

- **Hardware keyboard:** Syd has his own note-input design, to be filled in when this phase comes up. It matters most if the app comes to the Mac. The basics so far:
  - The home row plays a piano's white keys, and the row above it plays the black keys.
  - A gesture changes which octave is being played.
  - The number keys change the note duration.
  - The space bar enters a rest. Typing lyrics is a separate mode, so Space can move to the next syllable there.
  - It's the same layout as Musical Typing in GarageBand and Logic, so Mac musicians may already know it.
- **Letter names, as an option:** letters A–G enter pitches, number keys choose a duration, the up and down arrows move pitch (with a modifier for an octave), and Delete removes. It's how Sibelius and Dorico enter notes, so it's there for people who know them, but it isn't the main design.
- **MIDI:** Core MIDI for USB and Bluetooth instruments (with Apple's Bluetooth MIDI pairing view). Note-by-note entry takes the pitch from the keyboard and the duration from the current setting. Real-time entry needs a click and rounding note timings to the nearest beat, and it can come later.
- Both produce the same edit commands as the Pencil, so undo works the same way everywhere.

## Documents and storage

A score document is a package holding the score model, the ink for each symbol, and the recognizer's next-best guesses. Being a package lets ink and score be saved separately, so a large ink history doesn't slow saving the score. MusicXML is for export, not the native format, because it has nowhere to put ink.

The training set belongs to the person, not to a score, so it lives in the app's own storage. Syncing it through iCloud means training on the iPad also teaches the iPhone. That can come after Phase 4.

## The "iPhone Duo"

I don't know that device. Layouts will adapt to the screen's size class, so a foldable or dual-screen iPhone gets the same code. If it has its own API (say, for the hinge) that's worth designing for, that goes here.

## Using a pretrained recognizer later

The HOMUS dataset (about 15,000 handwritten music symbols drawn on screen by about 100 musicians, in 32 classes) could seed a base model that your samples then fine-tune. It could also give a starting set of templates, so the app does something reasonable before training is finished. Its license needs checking before anything trained on it ships in the app.

# References

- SMuFL specification: https://w3c.github.io/smufl/
- Bravura and Petaluma: https://github.com/steinbergmedia
- Leland: https://github.com/MuseScoreFonts
- MusicXML 4.0: https://www.w3.org/2021/06/musicxml40/
- The $P and $Q recognizers (Vatavu, Anthony, Wobbrock), at the University of Washington's ACE Lab $-family page
- The HOMUS dataset: Calvo-Zaragoza and Oncina, "Recognition of Pen-Based Music Notation: The HOMUS Dataset," ICPR 2014
- Apple documentation: PencilKit, `UIPencilInteraction` (squeeze and double-tap), `AVAudioUnitSampler`, Core MIDI
- The reference release flow: MarkdownPreviewApp's `Scripts/` and `Version.xcconfig`
