#lang info

(define version "3.0")
(define collection "qi")
(define deps '("base"
               ("fancy-app" #:version "1.1")
               "syntax-spec-v1"
               "macro-debugger"))
(define build-deps '())
(define clean '("compiled" "private/compiled"))
(define pkg-authors '(countvajhula))
