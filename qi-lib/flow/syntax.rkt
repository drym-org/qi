#lang racket/base

(provide literal
         subject
         clause
         sieve-form
         starts-with)

(require syntax/parse
         racket/string)

(define-syntax-class literal
  (pattern
   (~or expr:boolean
        expr:char
        expr:string
        expr:bytes
        expr:number
        expr:regexp
        expr:byte-regexp)))

(define-syntax-class subject
  #:attributes (args arity)
  (pattern
   (arg:expr ...)
   #:with args #'(arg ...)
   #:attr arity (length (syntax->list #'args))))

(define-syntax-class clause
  (pattern
   expr:expr))

;; Note that in these syntax classes, we reintroduce the name of the form
;; in the leading position in the constructed syntax attributes. Since we
;; match as ~datum in the form parsers this should be fine, but if that
;; ever changes it might make sense to propagate the input syntax
;; itself instead, e.g. with a #:when check instead of using ~datum to
;; match here.
(define-syntax-class sieve-form
  #:attributes (form)
  (pattern
   ((~datum sieve) condition:clause
                   sonex:clause
                   ronex:clause)
   #:with form #'(sieve condition sonex ronex))
  (pattern
   (~datum sieve)
   #:with form #'sieve)
  (pattern
   ((~datum sieve) arg ...)
   #:with form #'(sieve arg ...)))

(define-syntax-class (starts-with pfx)
  (pattern
   i:id #:when (string-prefix? (symbol->string
                                (syntax-e #'i)) pfx)))
