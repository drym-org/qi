#lang info

(define collection "qi")
(define deps '("base"))
(define build-deps '("scribble-lib"
                     "scribble-abbrevs"
                     "racket-doc"
                     "sandbox-lib"
                     "fancy-app"
                     "math-lib"
                     "quickscript"
                     "quickscript-extra"
                     "qi-lib"
                     "Qi-Quickscripts"
                     "threading-doc"
                     "relation"))
(define scribblings '(("scribblings/qi.scrbl" (multi-page))))
(define clean '("compiled" "doc" "doc/qi"))
