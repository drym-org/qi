#lang info

(define version "5.0")
(define collection "qi")
(define deps '("base"
               ("fancy-app" #:version "1.1")
               "syntax-spec-v2"
               ;; we do need this, but it does need to be
               ;; dynamic-require'd, so raco doesn't see
               ;; it as a compile-time dependency
               "macro-debugger"))
(define build-deps '())
(define clean '("compiled" "private/compiled"))
(define pkg-authors '(countvajhula))
