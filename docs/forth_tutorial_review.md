# Review: `docs/forth_tutorial.md`

A critical read of the tutorial as it stands (3637 lines, 18 sections plus
Appendix A), against the actual word set implemented in `core/`,
`kernel/` and `rom/`, and against the Jupiter Ace manual
(`docs/JA-Ace4000-Manual-First-US-Edition.pdf`) as a comparable model.

This is a review, not a rewrite. Nothing in `forth_tutorial.md` was
edited.

---

## Summary

**What's strong.** Coverage is much better than a spot check would
suggest. Every one of the 140 words the shipping ROM defines appears in
Appendix A, and 127 of them appear in at least one runnable example.
The prose is genuinely good: it explains *why* rather than only *what*,
it anticipates the specific mistakes a BASIC programmer makes, and it
is consistently honest about limits (`PICK` doesn't bounds-check, `F.`
truncates, `FILL` no-ops under `HIRES`, ULAplus is emulator-only). The
running device of "make a spare copy before you consume anything" is
threaded through the whole document and pays off repeatedly. The
`?DUP`-with-and-without and `MAYBE-RECORD` longhand-vs-`MAX`
comparisons are the two best teaching moments in the document.

**What's missing.** Three things, in order of size:

1. **No exercises anywhere.** 3637 lines, zero. The Ace manual ends
   every one of its 26 chapters with a Summary and numbered Exercises,
   and its introduction tells the reader outright not to skip them
   because they "often make interesting points that the main part of the
   chapter doesn't cover." This is the largest single structural
   difference between the two documents.
2. **Ordering problems that hurt a first read**, chiefly §3 (floating
   point, 318 lines, arriving before the reader has met `IF`) and §13
   (typing and editing, arriving ~2500 lines after §1 tells the reader
   to go type things and trip an error deliberately).
3. **13 words with no worked example**, and a further 41 carried by a
   single example line.

Separately, and independent of all of the above: **the `ACCEPT` example
at lines 2380 and 2411 is broken** — it uses `!` (a two-byte store)
where it needs `C!`, silently nulling the first character of whatever
the reader types. Details under "Factual corrections" below. This is the
one thing in the review that is a bug rather than an improvement.

**Top 3 priorities.**

1. Add `### Summary` and `### Exercises` to every section (§1 of the
   Ace-model recommendations below). This fixes the pedagogy gap *and*
   absorbs most of the 13 uncovered words in the same edit.
2. Move §13 (Typing and editing) to become §2, and split §3 so the
   integer arithmetic stays early and the whole float/trig subsystem
   moves to a late section.
3. Add an alphabetical glossary appendix and an error-message appendix
   (Ace Appendices B and C), both of which can be built largely
   mechanically from material that already exists.

---

## 1. Word coverage audit

### Method

Every dictionary word in this Forth is declared as

```
H_<NAME>:
    DW   <chain>
    DB   <len>, "<chars>"
W_<NAME>:
```

Extracting every `H_` label across `core/`, `kernel/`, `rom/`,
`include/`, `audio/`, `demos/` and `debug/` and reading the following
`DB` name line (allowing for the `$80` immediate bit and for long
comment blocks between `DW` and `DB`) gives **142 headers / 141 unique
names**:

- `BEEP` is defined twice — `core/beep.asm` (semitone/duration, the
  real one) and `core/rawbeep.asm` (raw pitch/duration). The shipping
  ROM `rom/forth_boot.asm` includes only `core/beep.asm`.
- `GETKEY` is ROM-local to `rom/forth_demo_blackjack.asm`, not part of
  the system.
- `core/decimal.asm` and `core/editor.asm` define **no** dictionary
  words (number-literal parsing and the line editor respectively); this
  was checked, not assumed.

`rom/forth_boot.asm` includes every `core/` file except `rawbeep.asm`,
so **the shipping word set is 140 words**.

Cross-referencing against the tutorial, counting an appearance inside a
fenced code block (with the `\ …` annotation stripped, so the annotation
text doesn't create false hits) as a *worked example*, and an appearance
in a table or in prose as a *mention*:

| Tier | Count | Meaning |
|---|---|---|
| **A — taught with a worked example** | 127 | appears in at least one runnable code block |
| **B — mentioned only** | 13 | in a table and/or prose, never in a code block |
| **C — missing entirely** | 0 | — |
| *(of which)* **thin** | 41 | tier A, but exactly one example line in the whole document |

Appendix A was checked separately: **all 140 words are present in it**.
That is a real achievement and worth protecting — it means the audit
below is about depth of teaching, not about words the document doesn't
know exist.

### Tier B — the 13 words with no worked example

| Word | Defined in | Where it currently appears | Suggested fix |
|---|---|---|---|
| `ROT` | `core/stackops.asm:38` | §1 table (309), prose at 337-338 comparing it to `PICK` | §1 needs one trace. `ROT` is the only one of the four "more shuffling" words with a genuinely non-obvious effect and it's the one most used in real code. A three-value trace in the style of the `OVER OVER SWAP` trace at 283-295 would cost eight lines. |
| `2DUP` | `core/stackops.asm:62` | §1 table (310) | Natural home is §4's string section: `2DUP TYPE` to print an `(addr len)` pair *and keep it* is the idiom that makes the word obviously worth having. |
| `2DROP` | `core/stackops.asm:78` | §1 table (311) | Pairs with the above — e.g. discarding a `SEARCH` result you didn't need, right beside the existing `SEARCH DROP TYPE` at 1309. |
| `?DUP` | — | *(covered, listed here only for contrast)* | Note how well `?DUP` is handled (§1 table + §6 payoff). That treatment is the model for `ROT`/`2DUP`/`2DROP`. |
| `XOR` | `core/logic.asm:76` | §3 table (933) only | `AND` and `OR` both get a worked line at 937-939; `XOR` is skipped in the same block. Add one line there — and it earns a better example than the other two, since XOR-toggling a byte with `C@`/`C!` is a real technique. |
| `SGN` | `core/mathfn.asm:68` | §3 table (822) | Add to the example block at 828-839, which already works through `ABS`, `MOD`, `SQRT`. Two lines. |
| `MOD` | `core/mathfn.asm:80` | *(one line, 833)* | Adequate but at the thin edge; flagged because the negative-dividend rule it states is exactly the sort of thing an exercise should make the reader verify. |
| `C,` | `core/dictspace.asm:80` | §17 table (3123), prose at 3128 | §17's example block (3133-3137) demonstrates `HERE`, `,` and `@` but never `C,`. Build a small byte table with `CREATE … C, C, C,` and read it back with `C@` — this also gives §17 a second `CREATE` shape besides the cell-based one. |
| `CLS` | `core/ts2068.asm:177` | §9 table (2055), prose at 2085 and 2221-2223 | Odd omission, since §9's graphics examples would naturally open with it. Add `CLS` to the head of the drawing example at 2065-2070. |
| `AT-XY` | `core/moregfx.asm:88` | §8 prose (1986), §9 table (2059) | Deserves better than a table row. A two-line status display rewritten in place inside a loop is the example — it's the one screen word that changes how you structure a program rather than just what appears. |
| `SPACES` | `core/outwords.asm:66` | §8 table (1998), prose 2024-2036 | The prose at 2024 describes using it to observe column wrap but never shows the line. A right-justified number column (Ace's own `TAB` exercise, ch12 ex4) is the better example. |
| `LOWER` | `core/stringext.asm:215` | §4 table (1240), prose 1265 | `UPPER` gets two example lines at 1249-1250; `LOWER` gets none in the same block. One line. |
| `CODE` | `core/stringext.asm:384` | §4 table (1244) | Never shown. `S" A" CODE .` printing 65 ties it directly to the `65 CHR TYPE` line two rows above it in the same table. |
| `F-` | `core/float.asm:368` | §3 prose only, at 662 ("`F+ F- F* F/`") | `F+`, `F*` and `F/` all get worked lines at 645-647; `F-` is the one omitted from that block. One line. |
| `STICK` | `core/stick.asm:39` | §9 prose 2364-2368 | Described but never shown. Worth a `BEGIN STICK . KEY? UNTIL`-style loop even though it reads 0 with nothing attached — the caveat is more convincing sitting next to a line the reader can actually run. |

### Tier A but thin — one example line only (41 words)

`/` `1-` `ABS` `AND` `ARRAY` `BORDER` `CHR` `CONSTANT` `COS` `DEG`
`EXECUTE` `F*` `FREE` `FROUND` `HIRES` `IMMEDIATE` `IN` `INVERT` `J`
`KEY?` `LEAVE` `LEFT` `LEN` `LINE` `LLIST` `LOAD-LIB` `LOAD-TEXT`
`LPRINT` `MOD` `OR` `PALETTE` `PICK` `PLACE` `RAD` `REPEAT` `RIGHT`
`S>F` `SAVE-TEXT` `SIN` `STR` `WHILE`

Most of these are fine — `RAD`/`DEG`/`SIN`/`COS` genuinely don't need
more than one line each. Four are undercovered for how important they
are:

- **`WHILE` / `REPEAT`** carry an entire loop shape between them and
  share exactly one example (`COUNTDOWN2`, 1630), which is deliberately
  written to do the same thing as the `BEGIN`/`UNTIL` example. The
  reader never sees `BEGIN…WHILE…REPEAT` doing something `UNTIL`
  couldn't. That was the whole argument for its existence (1620-1625).
- **`LEAVE`** has one example (`FINDTHREE`, 1750) and the trickier claim
  — "`LEAVE` exits only the loop it's directly inside" (1756) — is
  asserted without a nested example, in a document that has a perfectly
  good nested loop (`TRIANGLE`) 100 lines later.
- **`EXECUTE`** and **`'`** are the mechanism `CATCH` is built on, and
  §2's single example (`' DOUBLE EXECUTE`, 614) is explicitly a no-op
  equivalent to just typing `DOUBLE`. The motivating case — dispatching
  to one of several words chosen at runtime, storing an `xt` in a
  `VARIABLE` — is described in prose at 620-627 and never shown.
- **`ARRAY`** gets one line (`5 ARRAY SCORES`, 1082) and then everything
  after it operates on `SCORES` through raw `CELLS`/`+`/`@`. That's
  correct and it's the point, but a small program that actually fills
  and totals an array in a `DO` loop is missing, and it's the most
  natural bridge between §4 and §7.

### Words the tutorial correctly reports as *absent*

Verified against the source — these do not exist and the tutorial is
right to say so: `TAN` (740), `K` (1916), `<=` `>=` `<>` (1396), `NOT`
(947, deliberately not provided). Additionally absent from the
implementation and **not** mentioned anywhere in the tutorial:

- **Return-stack words** — there are no `>R`, `R>`, `R@`. Worth one
  sentence, because a reader coming from any other Forth text will look
  for them.
- `ROLL`, `DEPTH`, `.S`, `+!`, `2SWAP`, `2OVER`.
- Number bases — no `HEX`/`DECIMAL`/`BASE`; this Forth is decimal-only.
  Ace devotes a whole chapter (17) to bases.
- Vocabularies — no `VOCABULARY`/`DEFINITIONS`/`CONTEXT` (Ace ch22).
- Any comment word. The tutorial says this at line 22, in the "How to
  read the examples" preamble, which is the right place — but it should
  also appear in the "differences" appendix recommended below, since
  it's the deviation most likely to bite someone pasting code from a
  Forth book.

`.S` deserves a separate note. For a *teaching* Forth it is the single
highest-value missing word: this document's most repeated warning is
that using the wrong stack "is usually not an error you see reported"
(685) and that a missing `CELLS` produces "numbers that make no sense"
(1107). Both symptoms are diagnosed instantly by a non-destructive stack
print. That's an implementation suggestion rather than a documentation
one, but it belongs in this review because the tutorial is where the
absence hurts.

### Factual corrections found while auditing

- **Lines 2380 and 2411 — the `ACCEPT` idiom is wrong, and it is the
  document's one outright broken example.** Both lines read:

  ```forth
  NAME 1 + 10 ACCEPT NAME !
  ```

  `!` is a **two-byte, little-endian** store — verified in
  `core/dict.asm:231`, `W_STORE`: it writes the low byte at `addr` and
  the high byte at `addr+1`. §4's own diagram (1186-1192) establishes
  that a `STRING` buffer is a **one-byte** count followed by the text.
  So `NAME !` writes the length correctly into the count byte at
  `NAME`, and then writes the length's high byte — `0` for any string
  shorter than 256 characters, i.e. always — over `NAME+1`, **which is
  the first character of the text just typed**.

  The following `NAME COUNT TYPE` therefore prints the right number of
  characters with the first one replaced by a null. It should be `C!`:

  ```forth
  NAME 1 + 10 ACCEPT NAME C!
  ```

  This appears twice — in the isolated example at 2379-2383 and again
  in the combined "standard small-program shape" at 2408-2416, which is
  the one a reader is most likely to type. Worth checking against a
  live prompt before fixing, but the source is unambiguous.

- **Line 2970**: "`LLIST` deliberately does not print the ~100 built-in
  words this Forth ships with". The real figure is **140**. (Line 3433's
  Appendix A intro is safely unnumbered.)
- **Lines 2571-2576 contradict lines 3391-3396.** §11 says "Real tape
  behavior on real hardware, or a real emulator's actual cassette
  playback, remains separately unverified. Don't yet treat this as
  proof…" §18 says the Blackjack source was round-tripped "including a
  real cassette-tape round trip in Fuse (not just the fake-tape hook…)"
  and gives step-by-step instructions for reproducing it. The §11 caveat
  is stale and should be narrowed to what's actually still unverified
  (real hardware, as distinct from real emulated cassette playback).

---

## 2. Organization critique

Section lengths, for reference:

```
 336  §1  What Forth actually is
 264  §2  Defining your own words
 318  §3  Numbers
 367  §4  Reading and writing memory directly
  80  §5  Comparisons and true/false
 144  §6  Making decisions: IF ELSE THEN
 415  §7  Repeating yourself
  81  §8  Printing
 385  §9  Drawing and sound
  79  §10 Variables, constants, and comparisons in combination
 109  §11 Saving and loading your work
  76  §12 A wider screen
 100  §13 Typing and editing at the prompt
 164  §14 Error handling: THROW and CATCH
  58  §15 Printing to a real printer
  67  §16 ULAPlus
 280  §17 Growing the dictionary yourself
  71  §18 A worked example: the Blackjack demo
 208  Appendix A
```

### 2.1 §3 (Numbers) is in the wrong place and doing two jobs

This is the most consequential ordering problem. §3 begins at line 637.
At that point the reader has met the stack, `.`, the shuffling words,
`:`/`;`, `IMMEDIATE` and `'`/`EXECUTE` — and nothing else. §3 then
immediately introduces:

- a **second stack** (654);
- `F+ F- F* F/` (645-647), `FSQRT` (720), `PI`/`SIN`/`COS` (728-735),
  `RAD`/`DEG` (746-756);
- `S>F`/`F>S`/`FROUND` (758-808), including a genuinely subtle
  floor-versus-round-versus-truncate distinction that takes 15 lines of
  careful prose to get right;
- and only *then*, at line 810, the plain integer words the reader has
  actually been needing since §1: `1+ 1- NEGATE * / ABS SGN MOD SQRT
  MAX MIN RND RANDOMIZE`, followed by `AND OR XOR INVERT` at 923.

So the integer arithmetic that §1's `5 3 +` obviously wants next is
buried *behind* 170 lines of floating point, trigonometry and
stack-crossing conversions, none of which the reader can use for
anything yet — there is no `IF`, no loop, no memory, and no reason to
compute a sine.

The Ace defers floating point to **chapter 15 of 26** — after decisions,
loops, sound, the character set, plotting, *and* tape. That's not an
accident of the Ace's integer-first design; it's that floats are a
self-contained subsystem with no dependents, so they cost nothing to
defer and cost a beginner a lot to encounter early.

There's also an unaddressed collision the current placement creates:
`.` has been "the word that prints" since line 113, and §3 line 642
introduces `.` as a decimal point inside a literal. Two meanings for the
same character, 500 lines apart, never remarked on.

**Recommendation.** Split §3.

- Keep an early **"3. More arithmetic"** containing what is now
  810-951: the integer table, the worked block at 828-839, `1+`/`1-`,
  `NEGATE` vs `INVERT`, `MAX`/`MIN`, `RND`/`RANDOMIZE`, and the bitwise
  operators. This is roughly 140 lines and every word in it is
  immediately usable.
- Move everything now at 637-808 (decimal literals, the two stacks,
  `F*` family, `FSQRT`, trig, `RAD`/`DEG`, `S>F`/`F>S`/`FROUND`) to a
  new late section, somewhere around the current §12-§14 range. Leave a
  three-line forward pointer where it is now: "numbers with a decimal
  point in them exist and live on their own separate stack; §N covers
  them."
- When the float section moves, add the one sentence about `.` meaning
  two different things.

### 2.2 §13 (Typing and editing) should be §2

§13 is 100 lines describing the key bindings, the `OK` confirmation, the
`?` unrecognized-word message, the `STACK?` reset, and `VLIST`. It
arrives at line 2691.

Three earlier passages are actively waiting on it:

- **Line 54-58** explains `?` and immediately forward-references §13.
- **Line 186-198** instructs the reader to type `.` on an empty stack
  *deliberately*, watch the nonsense number and the `STACK?`, and says
  "Seeing that once now, deliberately, is much nicer than meeting it by
  accident later" — then forward-references §13 for the explanation.
- **Line 419-422** tells the reader that a `?` after defining a word
  means a missing space, and forward-references §2's own space
  breakdown.

That's the document telling the reader three times, in its first 420
lines, to go and interact with the machine — while the section that
explains what the machine says back sits 2500 lines away. The Ace puts
"Typing at the keyboard" at **chapter 2** and "Altering word
definitions / how to correct mistakes" at **chapter 7**.

I checked the dependency direction: nothing in §13 requires anything
past §1. The key table, `OK`/`?`/`STACK?`, and `VLIST` all need only
"words live in a dictionary and are looked up newest-first," which is
§1 lines 48-67.

**Recommendation.** Promote §13 to §2 ("At the keyboard"), before
"Defining your own words." The three forward references above become
back references. `VLIST` in particular stops being a curiosity and
becomes the tool the reader uses from that point on — which §2's own
line 393 already tries to do, by invoking `VLIST` to prove a new
definition landed, while pointing forward to a section 2300 lines later
for what it means.

`FORGET` (currently §17, 3298-3356) should probably follow it there too.
It is a correcting-mistakes tool, its own text cross-references §13
twice, and the Ace groups exactly this material ("Altering word
definitions") early rather than filing it under dictionary internals.

### 2.3 §8 (Printing) teaches words the reader has already used six times

`EMIT` first appears at line 1700 (`: STAR 42 EMIT ;`), `CR` at 1701,
and both are used again in `TRIANGLE` and `DIGITS` (1843-1902). §8, at
line 1961, then formally introduces them — and its own subsection at
2010 opens "None of this is new, only combined."

§7 works around this awkwardly: line 1707 explains `EMIT` parenthetically
and points forward to §8; line 1904 does the same for `48 + EMIT`.

**Recommendation.** Either fold `EMIT`/`CR`/`SPACE`/`SPACES` into the
existing `.` material in §1 (they are three thin wrappers around `EMIT`
and one primitive — perhaps 25 lines), or move §8 wholesale to sit
before §7. The second is cleaner and preserves §8's good material on
the column-32 wrap and the shared print position. As it stands §8 is a
consolidation interlude wearing a teaching section's number.

### 2.4 §9 (Drawing and sound) is five topics under a two-topic heading

At 385 lines it is the second-longest section, and it contains:

| Lines | Topic |
|---|---|
| 2042-2129 | Drawing: `PLOT` `LINE` `CIRCLE` `FILL` `CLS` `BORDER` `INK` `PAPER` `AT-XY` |
| 2131-2178 | Sound: `BEEP`, `SOUND` |
| 2180-2224 | `HIRES`/`NORMAL` |
| 2226-2280 | Ports: `IN`/`OUT` |
| 2282-2321 | `UDG` |
| 2323-2423 | Input: `KEY` `KEY?` `STICK` `ACCEPT` `INPUT` |

Two of those six are not drawing or sound at all. Input in particular is
100 lines of genuinely different material — it's the section a reader
looking for "how do I ask the user a question" needs, and it's filed
under a heading that gives no hint it's there.

**Recommendation.** Split into three or four sections: Drawing (with
`HIRES`/`NORMAL` and `UDG` alongside it), Sound, Input, and either fold
`IN`/`OUT` into the Sound section (where `SOUND`-as-two-`OUT`s at
2243-2255 already makes the transition beautifully) or give it its own
short section next to §17's other low-level material.

### 2.5 The hardware material is interleaved with review material, badly

Current back half: §9 hardware → §10 **review** → §11 storage → §12
64-col → §13 **editing** → §14 errors → §15 printer → §16 ULAPlus →
§17 dictionary internals → §18 worked example.

The three display-mode sections (§9's `HIRES`, §12's `64COL`, §16's
ULAplus) are all "other ways this screen can behave," they share the
same honest-caveat structure, and they are separated by four unrelated
sections. §11 (storage) and §15 (printer) are both "getting data out of
the machine" and are separated by three.

**Recommendation.** Group them: Drawing → other display modes (`HIRES`
already there, `64COL`, ULAplus) → Sound → Input → Storage and printer.
With §10 retitled and §13 promoted (below), the back half becomes a
clean run of machine chapters followed by §17 and §18.

### 2.6 §10 is a review section with a topic section's title

"Variables, constants, and comparisons in combination" introduces no new
word — its own text says so at 2446 ("Nothing here is a new word"). The
content is good; the `MAYBE-RECORD` longhand-versus-`MAX` comparison at
2470-2502 is one of the two best passages in the document. But the title
promises new material and the position interrupts the run into the
hardware sections.

**Recommendation.** Retitle as an explicit interlude ("Putting it
together: a worked example") and move it to directly follow §6, where
the `?PRINT` shape it recapitulates was introduced. Or promote it into
§18 as the small worked example that §18 currently lacks (see below).

### 2.7 §5 is thin for how much rests on it

80 lines, the shortest teaching section, and it carries: the whole
concept of a flag, the `-1`-not-`1` convention, the operand-order trap
for `<`/`>`, the `0=`-as-logical-negation double meaning, and the
absence of `<=`/`>=`/`<>`. It has one worked block (1353-1359) plus one
line at 1385.

That last point in particular — "Build what you need from what's here —
`<=` is `>` followed by `0=`" (1396-1398) — is stated and never shown.
It is the perfect exercise, and the sort of thing the Ace would make an
exercise: *define `<=`, `>=` and `<>` as colon definitions; check them
against the boundary cases.*

### 2.8 §17 is excellent and only slightly misplaced

`HERE`/`,`/`C,`/`ALLOT`/`CREATE`/`DOES>`/`FORGET` at 280 lines is the
most Forth-shaped material in the document and it delivers on the claim
§2 makes at line 377. The Ace also puts its equivalent late (ch20 of
26), so the position is defensible. The difference is that the Ace has
six chapters after it; here it's followed only by §18. Combined with the
recommendation to move `FORGET` earlier, §17 becomes purely
"CREATE/DOES>/dictionary space," which is a tighter and better section.

### 2.9 The introduction doesn't triage its readers

Lines 1-33 tell the reader that sections build on each other and should
be read in order. The Ace's introduction (lines 172-185 of the extracted
text) does something more useful: it names three kinds of reader and
tells each where to start — already know Forth (skim, then Appendix D),
learning Forth (start at the beginning, and *do the exercises*), just
want to run someone else's program (chapters 2 and 3 only).

**Recommendation.** Add a short "who this is for and where to start"
block. For this project the three groups are: knows BASIC but not Forth
(read straight through); already knows Forth (read §1's dictionary
notes, then the differences appendix and the glossary); wants a
reference (Appendix A, and the glossary appendix).

---

## 3. What to borrow from the Jupiter Ace manual

The Ace manual is 184 pages, 26 chapters, four appendices and an index.
Five things it does structurally that this tutorial should adopt.

### R1. Per-chapter Summary + Exercises — the biggest single win

Every Ace chapter ends with two blocks. `Summary` is bare: one or two
concept lines and then a flat list of the FORTH words introduced. For
ch5 it is literally:

```
Summary
  The stack
  FORTH words +, -, *, /, MOD, /MOD, NEGATE, 1+, 1-, 2+, 2-, */,
  */MOD, MAX, MIN, ABS
```

`Exercises` is 2-5 numbered items. Crucially the introduction warns the
reader that the exercises "often make interesting points that the main
part of the chapter doesn't cover, so don't overlook them even if you
don't feel like doing them" — and that's true: ch5's exercises are where
the 16-bit overflow behaviour, the `*/` double-length trick, and stack
underflow all get taught.

**Concrete change.** Add `### Summary` and `### Exercises` to each of
§§1-18.

- The Summary block is nearly free — Appendix A already has the word
  lists, grouped by topic; a per-section version is a regrouping of
  material that exists.
- The Exercises block is real work but the tutorial already contains
  several exercises written as prose. Convert these first:
  - **line 186-198** — "type `.` on an empty stack deliberately and
    watch `STACK?`". This is verbatim Ace ch5 exercise 4. Make it an
    exercise.
  - **line 2024-2036** — "`40 STARS` to watch the column-32 wrap".
  - **line 2268-2270** — "that round trip is worth typing once", of the
    `IN`/`OUT` sound-register read-back.
  - **line 368-369** — "it's worth a few minutes at the keyboard now
    rather than later — push some numbers, print them back".
- Then use exercises to absorb the 13 uncovered words from §1 of this
  review. Suggested pairings, one per section:
  - §1: write `2SWAP` using `ROT` and `SWAP`; check it with a trace.
    (Also introduces `ROT` properly.)
  - §3: what does `32767 1+ .` print? What about `256 256 * .`? (see
    Expanded Ideas below); add `SGN` and `XOR` here.
  - §4: print an `(addr len)` pair twice using `2DUP`, then clean up
    with `2DROP`. Use `CODE` to get a character's code without `C@`.
  - §5: define `<=`, `>=` and `<>`.
  - §7: rewrite `COUNTDOWN` as a `DO`/`LOOP`; then rewrite `FIVE` as a
    `BEGIN`/`UNTIL`. Which reads better, and why?
  - §8: print a right-justified column of numbers using `SPACES`
    (this is Ace ch12 exercise 4's `TAB`, adapted).
  - §9: draw a colour bar using `CLS` and `AT-XY`; play a scale with
    `DO … BEEP LOOP`.
  - §17: build a byte table with `CREATE … C, C,` and read it with
    `C@`.

### R2. An alphabetical glossary appendix with a notation legend

Ace Appendix C ("The Jupiter Ace — for reference") opens with a legend —
`n` single-length integer, `d` double, `u` unsigned, `f` float, `I`
immediate, `C` compile-only — and then lists every word **alphabetically**
with its stack effect and a one-or-two-line description.

The tutorial's Appendix A is grouped **by topic** with stack effects
only. That's good for browsing ("what can I do to the screen?") and
useless for the other lookup direction ("I saw `PLACE` in someone's
code, what does it do?"). Both directions matter and Ace provides both
(it also has a page-referenced index).

**Concrete change.** Keep Appendix A exactly as it is; add Appendix B, an
alphabetical glossary of all 140 words.

- The one-line descriptions largely exist already: every `core/*.asm`
  word carries a `; <NAME> ( … -- … )  <description>` comment above its
  `H_` label. That's a mechanical extraction, not new writing.
- Add the legend, and mark the **14 IMMEDIATE / compile-only words** —
  `;` `."` `S"` `IF` `ELSE` `THEN` `BEGIN` `UNTIL` `WHILE` `REPEAT` `DO`
  `LOOP` `+LOOP` `LEAVE` `EXIT`. The tutorial currently conveys this
  only as prose in §2 (547-557) and as scattered "compile-only" notes in
  Appendix A. A column is clearer and it is the property that most often
  explains a confusing error.

### R3. A numbered error-message appendix

Ace Appendix B lists each error code with its meaning, its likely
causes, and a chapter cross-reference; chapters point back into it
("Look up Error 4 in Appendix B"). Error 4 in particular lists *every*
word that can cause it.

2068-Forth's error surface is currently scattered across five sections:
`?` and `WORD ?` (§1 54-58, §13 2727-2739), `OK` (§13 2741), `STACK?`
(§1 186-198, §13 2745-2753, §14 2882-2889), `FORGET: BUILT-IN, REFUSED`
and `FORGET: NOT FOUND` (§17 3340, 3354), and THROW code `-8` for
dictionary overflow (§11 2561). That last one is orphaned — it cites an
ANS standard code without saying whether the system uses any others.

**Concrete change.** One appendix table: message text | what it means |
usual causes | which section explains it. Then make each in-body
occurrence a pointer into it. This also resolves the `-8` question, and
gives §14 (THROW/CATCH) somewhere to say which codes the system itself
throws versus which are yours to choose.

### R4. Interleave the machine chapters, and keep each one short

Ace's spine alternates language and machine: decisions (9) → repeating
(10) → **sound** (11) → **character set** (12) → **plotting** (13) →
**tape** (14) → fractions (15) → **keyboard** (16). Each machine chapter
is short, single-topic, and reachable with the language the reader has
at that point. That's *why* the Ace's hardware material doesn't feel
bolted on — not because it's better written, but because it arrives as
soon as it's usable.

**Concrete change**, beyond the splitting in §2.4 above: move **Sound**
to sit directly after §7 (Repeating yourself). A `DO … BEEP LOOP` scale
is the single most motivating thing a beginner can do with a loop, and
the tutorial already knows this — §9's `DOTS` example (2112) exists
precisely to show a loop driving a hardware word, but it's 400 lines
downstream of the loop section. Similarly, move `UDG` adjacent to
`EMIT`'s character-code discussion; §9 line 2284 currently re-explains
character codes from scratch because it's so far from §8.

### R5. A one-page "for people who already know Forth" appendix

Ace Appendix D is a single page: "Ace FORTH is based on FORTH-79, the
principal differences being…", five numbered items — including item 6,
a blunt list of standard words the Ace *lacks*.

2068-Forth needs this more than the Ace did, because its deviations are
numerous and are currently discoverable only by reading all 3637 lines:

- no comment word at all, neither `\` nor `(` (line 22)
- true is `-1`; `INVERT` is not `NOT`; `0=` is the logical negation
  (947-951, 1363-1393)
- no `<=` `>=` `<>` (1396)
- no return-stack words `>R` `R>` `R@` (not currently stated anywhere)
- no `ROLL` `DEPTH` `.S` `+!` `2SWAP` `2OVER`
- no `HEX`/`DECIMAL`/`BASE` — decimal only
- no vocabularies
- no `TAN` (740); no `K` for a third loop level (1916)
- `F.` always shows exactly 4 places and truncates (701-705)
- `/` truncates toward zero (830); `MOD` takes the dividend's sign (833)
- division by zero returns `0` rather than erroring (843-845)
- `VAL` returns `0` on unparseable text (1219)
- `SEARCH` returns the *rest of the string from the match*, not the
  match (1295-1303)
- `F>S` floors rather than truncating (794-802)
- `PICK`, `UDG`, `@`/`!`, `IN`/`OUT` do no bounds checking (344, 2318,
  2272)
- `DO` does not guard `start == limit` (1715-1723)

**Concrete change.** Collect all of the above into one appendix. Each
item is one line and every one already exists as prose somewhere in the
body; this is a gathering exercise, and it's the appendix an experienced
Forth programmer will read first.

---

## 4. Expanded ideas

Things worth adding that go beyond covering missing words.

### 4.1 16-bit range and silent overflow

The tutorial never warns that arithmetic wraps. `-32768`/`32767` appear
once (893-900) purely as an aside about signed comparison in `MAX`.
Meanwhile `*` was added in Phase 54 and will silently produce garbage
for perfectly reasonable inputs.

Ace ch5 exercises 2 and 3 handle this with a diagram — a circle of
values showing `32767` adjacent to `-32768` — and two one-liners:
`32767 1+ .` printing `-32768`, and `256 256 * .` printing `0`. It then
notes that `32768 .` doesn't even *read in* correctly.

This is a real trap in a language whose whole model is "numbers on a
stack" and it costs about fifteen lines. Put it in the promoted
integer-arithmetic section, with the diagram.

### 4.2 A "common mistakes" checklist appendix

The document already contains roughly a dozen first-rate trap write-ups.
They're scattered, and a reader debugging at 11pm needs the list, not
the prose:

| Trap | Currently at |
|---|---|
| Missing space glues two words together | §2, 403-422 |
| `!` wants value-then-address | §4, 976-982 |
| Missing `CELLS` on an array index | §4, 1100-1123 |
| Missing `@` on a `VARIABLE` | §4, 1023-1026 |
| Using `+` on floats (or `F+` on integers) | §3, 685-693 |
| `<`/`>` operand order | §5, 1372-1376 |
| `THEN` means "end", not "do this" | §6, 1442-1448 |
| `0 0 DO` is a near-infinite loop | §7, 1715-1734 |
| `+LOOP`'s step must be pushed inside the body | §7, 1932-1937 |
| Two `S"` on one prompt line collide | §4, 1286-1293 |
| `IMMEDIATE` marks whatever is newest | §2, 598-602 |
| `FORGET` takes everything defined after it | §17, 3319-3333 |
| `LOAD-LIB` restores only what existed at `SAVE-LIB` time | §11, 2537-2558 |

One appendix table — symptom | cause | section — with a "symptom" column
written from the reader's point of view ("a number comes back that makes
no sense" rather than "you forgot `CELLS`").

### 4.3 A second worked program, much smaller than Blackjack

§18 points at `demos/blackjack.fs`, "a few hundred lines." Between the
tutorial's three-line examples and that, there is nothing. The Ace fills
exactly this gap with chapter-end programs of 10-25 lines (the moving
train in ch12 ex1, `DRAW` in ch13 ex1, `TABLE` in ch12 ex4) that are
small enough to type and read in one sitting.

Suggested: a 30-40 line number-guessing game — `RANDOMIZE`/`RND` for the
target, `INPUT` for the guess, `<`/`>`/`=` for the feedback, `BEGIN`…
`UNTIL` for the loop, `."`/`CR` for the messages, `BEEP` for the win.
Built up incrementally across a section, one small word at a time, it
demonstrates the compose-small-words style §2 preaches (469-505) at a
scale the current examples never reach. It also naturally exercises
`ARRAY`, `AT-XY` and `CLS` if extended slightly.

### 4.4 More "the same problem, solved twice"

The strongest teaching device in the document appears exactly twice:
`?PRINT` with and without `?DUP` (§6, 1514/1531), and `MAYBE-RECORD`
longhand versus `MAX` (§10, 2474/2495). Both are outstanding. Good
further candidates, all using words that already exist:

- `COUNTDOWN` as `BEGIN`/`UNTIL` versus as `DO`/`LOOP` — this would
  simultaneously fix the `WHILE`/`REPEAT` thinness noted in §1.
- A hand-rolled constant (`CREATE … , … @`) versus `CONSTANT` — §17
  already gestures at this at 3189-3194 but doesn't run both.
- A `DO`-loop character comparison versus `SEARCH`.
- Indexing an array by hand (`n CELLS name + @`) versus a `DOES>`
  defining word — §17's `ARR3` (3264) is 90% of the way there already
  and just needs the two shown side by side.

### 4.5 Two diagrams the document needs and doesn't have

Currently four images: boot screen, drawing example, live editing, typo
error. All are screenshots of output. The Ace uses *explanatory*
diagrams — the number circle, the pixel-coordinate grid, character-cell
bit layouts.

Two places where a diagram would do more than the prose does:

- **The two stacks (§3, 668-683).** Currently an ASCII trace table. A
  side-by-side picture of the two piles, with the point that no word
  can see across, would land the "they will never see each other's
  values" claim (666) far harder.
- **The dictionary and `HERE` (§17).** `HERE` as the frontier, growing
  upward, with `,`/`C,`/`ALLOT` advancing it and `FORGET` rewinding it
  to a marked point, is a picture that would carry the entire section.
  §4's string-buffer diagram (1186-1192) shows the author can already do
  this well.

### 4.6 An index, or at least reverse links

Ace has a page-referenced alphabetical index that includes every word
symbol (`!`, `#`, `*/MOD`, …). The `.docx` pipeline is a plausible place
to generate one. Failing that, the markdown could carry anchor links
from each Appendix A row back into the body section that teaches it —
the cross-references currently run one way only, body → appendix.

### 4.7 Small things

- **`STICK`'s honest caveat** (2366-2368) says both devices read `0`
  with nothing connected, "true of every setup this has been tested
  against so far." That's the right kind of honesty but it leaves the
  word untestable. Worth stating what a reader *would* see with a
  joystick attached, so the word is at least specified.
- **`LOAD-LIB` with no name** (2530) is mentioned in one clause and
  never shown. It's the more convenient of the two forms.
- **§14's `CATCH` example set is good but never shows nesting.** The
  claim that a `THROW` unwinds "past every `CATCH`" for `ABORT` (2948)
  versus reaching "the nearest `CATCH`" for `THROW` (2807) would be
  much clearer with one two-level example.
- *(The `ACCEPT` idiom problem was promoted to "Factual corrections"
  in §1 — it's a real bug, not a stylistic note.)*
