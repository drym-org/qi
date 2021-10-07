#lang racket/base

(provide switch
         switch-lambda
         define-switch
         λ01)

(require syntax/parse/define
         racket/stxparam
         mischief/shorthand
         (only-in racket/function
                  const)
         (for-syntax racket/base)
         "flow.rkt"
         "on.rkt")

(define-syntax-parser switch
  [(_ args:subject
      [predicate:clause consequent]
      ...)
   #`(on args
       (switch [predicate consequent] ...))])

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
