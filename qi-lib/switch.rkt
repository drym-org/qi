#lang racket/base

(provide switch
         switch-lambda
         define-switch
         λ01)

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
  [(_ args:formals expr:expr ...)
   #:with ags (attribute args.params)
   #'(lambda args
       (switch ags
         expr ...))])

(define-alias λ01 switch-lambda)

(define-syntax-parser define-switch
  [(_ ((~or head:id head:function-header) . args:formals)
      expr:expr ...)
   #'(define head
       (switch-lambda args
         expr ...))]
  [(_ name:id expr:expr ...)
   #'(define name
       (☯ (switch expr ...)))])
