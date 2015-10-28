bash
====

find . -type d 2>/dev/null | xargs du -hs * 2>/dev/null | sort -uh
