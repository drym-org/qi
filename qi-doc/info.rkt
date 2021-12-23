#lang info

(define collection "qi")
(define deps '("base"))
(define build-deps '("scribble-lib"
                     "scribble-abbrevs"
                     "scribble-math"
                     "racket-doc"
                     "sandbox-lib"
                     "from-template"
                     "quickscript"
                     "quickscript-extra"
                     "Qi-Quickscripts"
                     "tmux-vim-demo"
                     "threading-doc"
                     "fancy-app"
                     "math-lib"
                     "qi-lib"
                     "qi-probe"
                     "relation"))
(define scribblings '(("scribblings/qi.scrbl" (multi-page))))
(define clean '("compiled" "doc" "doc/qi"))
