#lang racket/base

(provide literal
         subject
         clause
         sep-form
         group-form
         switch-form
         sieve-form
         try-form
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

(define-syntax-class sep-form
  #:attributes (form)
  (pattern
   (~or (~or (~datum △) (~datum sep))
        ((~or (~datum △) (~datum sep)) onex:clause))
   #:with form this-syntax))

(define-syntax-class group-form
  #:attributes (form)
  (pattern
   (~or ((~datum group) n:expr
                        selection-onex:clause
                        remainder-onex:clause)
        (~datum group)
        ((~datum group) arg ...))
   #:with form this-syntax))

(define-syntax-class switch-form
  #:attributes (form)
  (pattern
   (~or ((~datum switch))
        ((~datum switch) ((~or (~datum divert) (~datum %))
                          condition-gate:clause
                          consequent-gate:clause))
        ((~datum switch) [(~datum else) alternative:clause])
        ((~datum switch) ((~or (~datum divert) (~datum %))
                          condition-gate:clause
                          consequent-gate:clause)
                         [(~datum else) alternative:clause])
        ((~datum switch) [condition0:clause ((~datum =>) consequent0:clause ...)]
                         [condition:clause consequent:clause]
                         ...)
        ((~datum switch) ((~or (~datum divert) (~datum %))
                          condition-gate:clause
                          consequent-gate:clause)
                         [condition0:clause ((~datum =>) consequent0:clause ...)]
                         [condition:clause consequent:clause]
                         ...)
        ;; consequent0 renamed to consequent2 below, because otherwise
        ;; the syntax class complains about "different nesting depths"
        ((~datum switch) [condition0:clause consequent2:clause]
                         [condition:clause consequent:clause]
                         ...)
        ((~datum switch) ((~or (~datum divert) (~datum %))
                          condition-gate:clause
                          consequent-gate:clause)
                         [condition0:clause consequent2:clause]
                         [condition:clause consequent:clause]
                         ...))
   #:with form this-syntax))

(define-syntax-class sieve-form
  #:attributes (form)
  (pattern
   (~or ((~datum sieve) condition:clause
                        sonex:clause
                        ronex:clause)
        (~datum sieve)
        ((~datum sieve) arg ...))
   #:with form this-syntax))

(define-syntax-class try-form
  #:attributes (form)
  (pattern
   (~or ((~datum try) flo
                      [error-condition-flo error-handler-flo]
                      ...+)
        ((~datum try) arg ...))
   #:with form this-syntax))

(define-syntax-class (starts-with pfx)
  (pattern
   i:id #:when (string-prefix? (symbol->string
                                (syntax-e #'i)) pfx)))
