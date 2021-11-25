#lang racket/base

(provide ~>
         ~>>)

(require syntax/parse/define
         (for-syntax racket/base
                     "flow.rkt")
         "flow.rkt"
         "on.rkt")

(define-syntax-parser ~>
  [(_ args:subject) #'(void)]
  [(_ args:subject clause:clause ...)
   #:with ags (attribute args.args)
   #`(on ags (~> clause ...))])

(define-syntax-parser ~>>
  [(_ args:subject) #'(void)]
  [(_ args:subject clause:clause ...)
   #:with ags (attribute args.args)
   #`(on ags (~>> clause ...))])
