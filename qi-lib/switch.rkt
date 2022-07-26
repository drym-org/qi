#lang racket/base

(provide switch
         switch-lambda
         define-switch
         λ01
         let/switch)

(require syntax/parse/define
         (only-in "private/util.rkt" define-alias)
         (for-syntax racket/base
                     syntax/parse/lib/function-header)
         "flow.rkt"
         "on.rkt")

(define-syntax-parser switch
  [(_ args:subject
      clause ...)
   #'(on args
       (switch clause ...))])

(define-syntax-parser switch-lambda
  [(_ rest-args:id expr:expr ...)
   #'(lambda rest-args
       (switch (rest-args)
               expr ...))]
  [(_ args:formals expr:expr ...)
   #:with ags (attribute args.params)
   #'(lambda args
       (switch ags
         expr ...))])

(define-alias λ01 switch-lambda)

(define-syntax-parser define-switch
  [(_ (head . args:formals) expr:expr ...)
   #'(define head
       (switch-lambda args
         expr ...))]
  [(_ name:id expr:expr ...)
   #'(define name
       (☯ (switch expr ...)))])

(define-syntax-parser let/switch
  [(_ ([var:id val:expr] ...) expr:expr ...)
   #'((switch-lambda (var ...)
        expr ...)
      val ...)])
