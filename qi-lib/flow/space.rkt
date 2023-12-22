#lang racket/base

(provide define-for-qi
         define-qi-syntax
         define-qi-alias
         reference-qi
         (for-syntax
          introduce-qi-syntax))

(require syntax/parse/define
         (for-syntax racket/base
                     syntax/parse/lib/function-header))

(begin-for-syntax
  (define introduce-qi-syntax
    (make-interned-syntax-introducer 'qi)))

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
   #:with spaced-name (introduce-qi-syntax #'name)
   #'(define spaced-name expr)]
  [(_ (name:id . args:formals)
      expr:expr ...)
   #'(define-for-qi name
       (lambda args
         expr ...))])

(define-syntax-parser define-qi-syntax
  [(_ name transformer)
   #:with spaced-name (introduce-qi-syntax #'name)
   #'(define-syntax spaced-name transformer)])

;; reference bindings in qi space
(define-syntax-parser reference-qi
  [(_ name)
   #:with spaced-name (introduce-qi-syntax #'name)
   #'spaced-name])

(define-syntax-parser define-qi-alias
  [(_ alias:id name:id)
   #:with spaced-name (introduce-qi-syntax #'name)
   #'(define-qi-syntax alias (make-rename-transformer #'spaced-name))])
