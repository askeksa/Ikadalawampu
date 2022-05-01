## Ikadalawampu by Loonies ##

This repository contains the source code and data files for the Amiga 4k intro [Ikadalawampu](https://www.pouet.net/prod.php?which=54561), which was released at Breakpoint 2010, winning the Amiga 4k intro competition. It is, as of May 2022, still the highest rated Amiga AGA 4k intro [on Pouet](https://www.pouet.net/toplist.php?type=4k&platform=71&limit=10&days=0).

### How to build ###

1. Assign `4k:` to the `4k` directory.
2. Load [`4k:Main.S`](4k/Main.S) into AsmPro.
3. Follow the instructions in that file to produce an executable.
4. Compress the executable using [Shrinkler](https://github.com/askeksa/Shrinkler) `--hunkmerge --mini` (or another cruncher that supports hunk merging).
