#lang racket/base

(provide literal
         subject
         clause
         starts-with)

(require syntax/parse
         racket/string)

(define-syntax-class literal
  (pattern
   ;; TODO: would be ideal to also match literal vectors, boxes and prefabs
   (~or* expr:boolean
         expr:char
         expr:string
         expr:bytes
         expr:number
         expr:regexp
         expr:byte-regexp
         ;; We'd like to treat quoted forms as literals as well. This
         ;; includes symbols, and would also include, for instance,
         ;; syntactic specifications of flows, since flows are
         ;; syntactically lists as they inherit the elementary syntax of
         ;; the underlying language (Racket). Quoted forms are read as
         ;; (quote ...), so we match against this
         ((~datum quote) expr:expr)
         ((~datum quasiquote) expr:expr)
         ((~datum quote-syntax) expr:expr)
         ((~datum syntax) expr:expr))))

(define-syntax-class subject
  #:attributes (args arity)
  (pattern
   (arg:expr ...)
   #:with args #'(arg ...)
   #:attr arity (length (syntax->list #'args))))

(define-syntax-class clause
  (pattern
   expr:expr))

(define-syntax-class (starts-with pfx)
  (pattern
   i:id #:when (string-prefix? (symbol->string
                                (syntax-e #'i)) pfx)))

