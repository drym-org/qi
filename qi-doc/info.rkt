#lang info

(define deps '())
(define build-deps '("scribble-lib"
                     "scribble-abbrevs"
                     "racket-doc"
                     "sandbox-lib"
                     "fancy-app"
                     "math-lib"
                     "quickscript"
                     "quickscript-extra"
                     "Qi-Quickscripts"
                     "threading-doc"
                     "relation"))
(define scribblings '(("scribblings/qi.scrbl" (multi-page))))
(define clean '("doc" "doc/qi"))
