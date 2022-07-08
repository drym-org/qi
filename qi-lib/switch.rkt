#lang racket/base

(provide switch
         switch-lambda
         define-switch
         λ01
         let/switch)

(require syntax/parse/define
         (only-in "private/util.rkt" define-alias)
         (for-syntax racket/base
                     "flow/aux-syntax.rkt")
         "flow.rkt"
         "on.rkt")

(define-syntax-parser switch
  [(_ args:subject
      clause ...)
   #'(on args
       (switch clause ...))])

(define-syntax-parser switch-lambda
  [(_ (arg:id ...) expr:expr ...)
   #'(lambda (arg ...)
       (switch (arg ...)
         expr ...))]
  [(_ rest-args:id expr:expr ...)
   #'(lambda rest-args
       (switch (rest-args)
         expr ...))])

(define-alias λ01 switch-lambda)

(define-syntax-parser define-switch
  [(_ (name:id arg:id ...) expr:expr ...)
   #'(define name
       (switch-lambda (arg ...)
         expr ...))]
  [(_ name:id expr:expr ...)
   #'(define name
       (☯ (switch expr ...)))])

(define-syntax-parser let/switch
  [(_ ([var:id val:expr] ...) body ...)
   #'(let ([var val] ...)
       (switch (var ...)
         body ...))])
