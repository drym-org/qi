#lang racket/base

(require syntax/parse/define
         mischief/shorthand
         (for-syntax racket/base
                     "flow.rkt")
         "flow.rkt")

(provide on
         flow-lambda
         define-flow
         π)

(define-syntax-parser on
  [(_ args:subject) #'(void)]
  [(_ args:subject clause:clause)
   #:with ags (attribute args.args)
   #`((flow clause) #,@(syntax->list #'ags))])

(define-syntax-parser flow-lambda
  [(_ (arg:id ...) expr:expr ...)
   #'(lambda (arg ...)
       (on (arg ...)
           expr ...))]
  [(_ rest-args:id expr:expr ...)
   #'(lambda rest-args
       (on (rest-args)
           expr ...))])

(define-alias π flow-lambda)

(define-syntax-parser define-flow
  [(_ (name:id arg:id ...) expr:expr)
   #'(define name
       (flow-lambda (arg ...)
         expr))]
  [(_ name:id expr:expr)
   #'(define name
       (flow expr))])
