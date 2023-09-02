#lang info

(define version "3.0")
(define collection "qi")
(define deps '("base"
               ("fancy-app" #:version "1.1")
               ;; this git URL should be changed to a named package spec
               ;; once syntax-spec is on the package index
               ;; "syntax-spec-v1"
               "git://github.com/michaelballantyne/syntax-spec.git#main"))
(define build-deps '())
(define clean '("compiled" "private/compiled"))
(define pkg-authors '(countvajhula))
