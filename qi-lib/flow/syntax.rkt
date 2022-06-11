#lang racket/base

(provide literal
         subject
         clause
         sep-form
         group-form
         switch-form
         sieve-form
         try-form
         fanout-form
         input-alias
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
  (pattern
   (~or (~or (~datum △) (~datum sep))
        ((~or (~datum △) (~datum sep)) onex:clause))))

(define-syntax-class group-form
  (pattern
   (~or ((~datum group) n:expr
                        selection-onex:clause
                        remainder-onex:clause)
        (~datum group)
        ((~datum group) arg ...))))

(define-syntax-class switch-form
  (pattern
   ((~datum switch)))
  (pattern
   ((~datum switch) ((~or (~datum divert) (~datum %))
                     condition-gate:clause
                     consequent-gate:clause)))
  (pattern
   ((~datum switch) [(~datum else) alternative:clause]))
  (pattern
   ((~datum switch) ((~or (~datum divert) (~datum %))
                     condition-gate:clause
                     consequent-gate:clause)
                    [(~datum else) alternative:clause]))
  (pattern
   ((~datum switch) [condition0:clause ((~datum =>) consequent0:clause ...)]
                    [condition:clause consequent:clause]
                    ...))
  (pattern
   ((~datum switch) ((~or (~datum divert) (~datum %))
                     condition-gate:clause
                     consequent-gate:clause)
                    [condition0:clause ((~datum =>) consequent0:clause ...)]
                    [condition:clause consequent:clause]
                    ...))
  (pattern
   ((~datum switch) [condition0:clause consequent0:clause]
                    [condition:clause consequent:clause]
                    ...))
  (pattern
   ((~datum switch) ((~or (~datum divert) (~datum %))
                     condition-gate:clause
                     consequent-gate:clause)
                    [condition0:clause consequent0:clause]
                    [condition:clause consequent:clause]
                    ...)))

(define-syntax-class sieve-form
  (pattern
   (~or ((~datum sieve) condition:clause
                        sonex:clause
                        ronex:clause)
        (~datum sieve)
        ((~datum sieve) arg ...))))

(define-syntax-class try-form
  (pattern
   (~or ((~datum try) flo
                      [error-condition-flo error-handler-flo]
                      ...+)
        ((~datum try) arg ...))))

(define-syntax-class input-alias
  (pattern
   (~or (~datum 1>)
        (~datum 2>)
        (~datum 3>)
        (~datum 4>)
        (~datum 5>)
        (~datum 6>)
        (~datum 7>)
        (~datum 8>)
        (~datum 9>))))

(define-syntax-class fanout-form
  (pattern
   (~or (~datum fanout)
        ((~datum fanout) n:number)
        ((~datum fanout) n:expr))))

(define-syntax-class (starts-with pfx)
  (pattern
   i:id #:when (string-prefix? (symbol->string
                                (syntax-e #'i)) pfx)))
