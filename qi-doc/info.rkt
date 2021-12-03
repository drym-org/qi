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
                     "qi-lib"
                     "Qi-Quickscripts"
                     "threading-doc"
                     "fancy-app"
                     "math-lib"
                     "relation"))
(define scribblings '(("scribblings/qi.scrbl" (multi-page))))
(define clean '("compiled" "doc" "doc/qi"))
