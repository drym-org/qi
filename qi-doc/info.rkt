#lang info

(define version "1.0")
(define collection "qi")
(define deps '("base"))
(define build-deps '("scribble-lib"
                     "scribble-abbrevs"
                     "scribble-math"
                     "racket-doc"
                     "sandbox-lib"
                     "from-template"
                     "tmux-vim-demo"
                     "threading-doc"
                     "debug"
                     "mischief"
                     "fancy-app"
                     "math-lib"
                     "qi-lib"
                     "qi-probe"
                     "relation"))
(define scribblings '(("scribblings/qi.scrbl" (multi-page))))
(define clean '("compiled" "doc" "doc/qi"))
