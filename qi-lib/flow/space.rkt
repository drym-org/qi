#lang racket/base

(provide define-for-qi)

(require syntax/parse/define
         (for-syntax racket/base
                     syntax/parse/lib/function-header))

;; Define variables in the qi binding space.
;; This allows us to define functions in the qi space which, when used in
;; qi contexts, would not be shadowed by bindings at the use site. This
;; gives us some of the benefits of core linguistic forms while also not
;; actually inflating the size of the core language nor incurring the
;; performance penalty it might if it were implemented as a macro
;; compiling to the core language.
;; See "A loophole in Qi space":
;;   https://github.com/drym-org/qi/wiki/Qi-Compiler-Sync-Jan-26-2023
(define-syntax-parser define-for-qi
  [(_ name:id expr:expr)
   #:with spaced-name ((make-interned-syntax-introducer 'qi) #'name)
   #'(define spaced-name expr)]
  [(_ (name:id . args:formals)
      expr:expr ...)
   #'(define-for-qi name
       (lambda args
         expr ...))])
