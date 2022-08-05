#lang racket/base

(provide switch
         switch-lambda
         switch-λ
         λ01
         define-switch)

(require syntax/parse/define
         (for-syntax racket/base
                     syntax/parse/lib/function-header)
         "flow.rkt"
         "on.rkt"
         (only-in "private/util.rkt"
                  define-alias
                  params-parser))

(define-syntax-parser switch
  [(_ args:subject
      clause ...)
   #'(on args
       (switch clause ...))])

(define-syntax-parser switch-lambda
  [(_ args:formals expr:expr ...)
   #:with ags (params-parser #'args)
   #'(lambda args
       (switch ags
         expr ...))])

(define-alias λ01 switch-lambda)
(define-alias switch-λ switch-lambda)

(define-syntax-parser define-switch
  [(_ ((~or* head:id head:function-header) . args:formals)
      expr:expr ...)
   #'(define head
       (switch-lambda args
         expr ...))]
  [(_ name:id expr:expr ...)
   #'(define name
       (☯ (switch expr ...)))])
