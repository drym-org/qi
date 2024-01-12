#lang racket/base

;; This name juggling is necessary since the Racket macros would
;; otherwise collide with the Qi forms with the same name in the qi
;; binding space, since Qi forms are now exported literals and not simply
;; matched as datum patterns as they were formerly.
(provide (rename-out [%switch switch])
         switch-lambda
         switch-λ
         λ01
         define-switch)

(require syntax/parse/define
         (for-syntax racket/base
                     syntax/parse/lib/function-header
                     "flow/aux-syntax.rkt")
         "flow.rkt"
         "on.rkt"
         (only-in "private/util.rkt"
                  define-alias
                  params-parser))

(define-syntax-parser %switch
  [(_ args:subject
      clause ...)
   #'(on args
       (switch clause ...))])

;; The parsed `ags' is being passed to `switch'
;; while the unparsed `args' are passed to `lambda',
;; so that `lambda' can bind keyword arguments in scope
;; while the flow itself does not receive them directly.
(define-syntax-parser switch-lambda
  [(_ args:formals expr:expr ...)
   #:with ags (params-parser #'args)
   #'(lambda args
       (%switch ags
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
       (flow (switch expr ...)))])
