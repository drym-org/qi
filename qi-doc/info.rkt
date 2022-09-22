#lang info

(define version "3.0")
(define collection "qi")
(define deps '("base"))
(define build-deps '("scribble-lib"
                     "scribble-abbrevs"
                     "scribble-math"
                     "racket-doc"
                     "sandbox-lib"
                     "qi-lib"
                     "qi-probe"))
(define scribblings '(("scribblings/qi.scrbl" (multi-page) (language))))
(define clean '("compiled" "doc" "doc/qi"))
