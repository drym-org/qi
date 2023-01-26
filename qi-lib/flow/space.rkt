#lang racket/base

(provide define-for-qi)

(require syntax/parse/define
         (for-syntax racket/base
                     syntax/parse/lib/function-header))

(define-syntax-parser define-for-qi
  [(_ name:id expr:expr)
   #:with spaced-name ((make-interned-syntax-introducer 'qi) #'name)
   #'(define spaced-name expr)]
  [(_ (name:id . args:formals)
      expr:expr ...)
   #'(define-for-qi name
       (lambda args
         expr ...))])
