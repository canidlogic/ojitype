# Ojitype keyboard

## Introduction

This document specifies the keyboard layout that is used for Ojitype.

The Ojitype system must be able to produce more than 200 symbols, but the keyboard has far fewer typing keys than that.  Therefore, some symbols must be built up with multiple keystrokes.  A _key sequence_ is a sequence of one or more keystrokes that is used to select the symbol to type.  Below the keyboard there is a _buffer box_ that displays the current key sequence that you are typing.

Ojitype allows you to type both western and eastern finals, and w-dots both on the left and the right of syllables.  This means that the Ojitype keyboard can accomodate various different styles of syllabics without needing any special configuration.

The Ojitype keyboard layout is designed to map syllabics characters to their closest equivalents in a QWERTY keyboard.  This allows people familiar with a QWERTY keyboard to use their QWERTY typing skills for syllabics.

## Keyboard mode

You may also want to use your system keyboard sometimes instead of the virtual keyboard that Ojitype provides.  You can switch between the Ojitype virtual keyboard and your system keyboard by using the keyboard radio buttons to switch between _Syllabics_ and _System._

## Key colors

Certain keys on the virtual keyboard are shown in different colors.  The following guide indicates their meanings:

__Gray__ keys correspond to the spacebar and the two keys that normally have physical notches on them to indicate where the index fingers are placed.  (On QWERTY keyboards, the F and J keys have notches on them.)

__Blue__ keys are used for placing w-dots and vowel length dots.  The ᐃ I-vowel symbol used on these keys is only for sake of illustrating the position of the dot.  The w-dot keys can also be used by themselves to type the W final, in which case both keys will produce the exact same final.  Attempting to type the vowel length dot by itself will be ignored, it can't stand alone.

Note also the top-left key corresponding to Q on a QWERTY keyboard, which is a dot but is _not_ a blue key.  This dot key is the western Y final, and it does _not_ combine with other symbols, unlike the dots in the blue keys.

__Green__ keys are punctuation marks.  Note that Ojitype uses the Shift key in a special way (described below under the gold keys), so it is not possible to have more than one punctuation mark on a single key, unlike in QWERTY keyboards where you can get a second symbol with the Shift key.  Instead of an ASCII period, Ojitype provides a syllabics full-stop symbol.  The punctuation mark that looks like an equals sign is actually a syllabics hyphen.  On a physical keyboard, you may use both the minus and equals keys to type the syllabics hyphen.

Ojitype provides you with both left and right double-quote punctuation marks, whereas QWERTY keyboards just have one double-quote punctuation mark.  It is especially important to use the left and right double-quote marks with syllabics to avoid confusion with the ᐦ H final.  No apostrophes or single quotes are provided because they are too easy to confuse for western finals.  As an alternative to quotation marks, the horizontal bar symbol is also provided as a punctuation mark.

Although not shown on the displayed virtual keyboard, the grave accent key and tilde key on QWERTY keyboards will produce a tilde, and the left and right square and curly brackets keys on QWERTY keyboards will produce square brackets.  Also, the enter and tab keys have their usual meanings.

__Gold__ keys are special keys.  The gold key marked with an X is the _flush_ key.  If you have keystrokes in the buffer box and you press the flush key, each buffered keystroke is typed as a separate symbol and the buffer is emptied.  Pressing the flush key when the buffer box is empty has no effect.  As a shortcut, if you press a certain key while holding down Shift, this is equivalent to pressing the flush key, pressing that certain key, and then pressing the flush key again.  This shortcut is useful for typing eastern finals.

The other gold key is the western final for M.  In almost all cases, western finals and eastern finals are either identical or completely different.  The sole exception is that the eastern final for T looks identical to the western final for M.  In Unicode, these two finals have different codepoints, even though they look identical.  You should use the gold key final _only_ when you want a western final for M.  __If you want the eastern final for T, do not use the gold key, even though it looks like the symbol you want!__  Instead, use the ᑕ T key and then the gold flush key to type the correct codepoint for eastern final T.

## Composition process

As was mentioned in the introduction, Ojitype uses key sequences to type symbols rather than individual keystrokes.

If you use Ctrl, Alt, Meta, or OS keys during a keystroke, or you press a key that is not part of the virtual keyboard (an arrow key or the backspace key, for example), then this is a __system__ keystroke.  When a system keystroke occurs, the buffer contents are discarded.  Certain user interface events may also have the effect of system keystrokes by discarding buffer contents.  Caps Lock is always ignored.

Certain keys are __atomic__ meaning that they always stand by themselves in a key sequence and can never be combined with other keystrokes.  The following keys are atomic:

- Punctuation mark keys (marked in green on the keyboard)

- All western final keys as well as the golden western M final key

- The ᐦ H final

- The medial symbols ᓬ L and ᕒ R

- The spacebar, tab key, and enter keys

When an atomic key is pressed, the buffer is first flushed as if the golden flush key were pressed before the atomic key.  Then, the symbol selected by the atomic key is typed.  The buffer is left empty after the atomic keystroke.

All keys on the virtual keyboard that are not atomic and not system can be used as part of composition sequences.  These keys are classified by the position they can occur in composition sequences:

1. Eastern final keys

2. The two blue w-dot keys

3. The blue vowel length key

4. Vowel keys (not including the blue w-dot and vowel length keys)

Vowel keystrokes always type a symbol, clearing the buffer in the process.  If nothing is in the buffer when a vowel keystroke occurs, the vowel is typed by itself.  Otherwise, everything currently in the buffer is combined with the vowel to select the appropriate syllabics character, and then the buffer is cleared.  Combining the vowel length key with an E vowel has no effect.

The vowel length key always adds itself to the end of the buffer, unless it is already at the end of the buffer, in which case it is ignored.  If the vowel length key is at the end of the buffer and you press the flush key or perform another keystroke that implicitly causes a buffer flush, the vowel length key is discarded from the buffer before flushing out the rest of the buffer, since the vowel length keystroke has no symbol by itself.

The w-dot keys add themselves to the end of the buffer unless a vowel length key or another w-dot key is currently at the end of the buffer, in which case an implicit buffer flush is performed and then the new w-dot key is added.  If the buffer is flushed while a w-dot keystroke is buffered, a W final is typed out in place of the w-dot keystroke.  Both w-dot keystrokes produce the exact same W final when flushed.

The eastern final keys always flush the buffer and then add themselves.  If the buffer is flushed while an eastern final is buffered, then the eastern final symbol is typed out.
