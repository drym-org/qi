#lang racket/base

(provide on
         flow-lambda
         define-flow
         π
         let/flow)

(require syntax/parse/define
         (for-syntax racket/base
                     "flow/aux-syntax.rkt")
         "flow.rkt"
         (only-in "private/util.rkt" define-alias))

(define-syntax-parser on
  [(_ args:subject)
   #:with ags (attribute args.args)
   #`((flow) #,@(syntax->list #'ags))]
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

(define-syntax-parser let/flow
  [(_ ([var:id val:expr] ...) body ...)
   #'(let ([var val] ...)
       (on (var ...)
         body ...))])
