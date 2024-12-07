#lang racket/base

(provide literal
         subject
         clause
         starts-with
         (struct-out deforestable-info))

(require syntax/parse
         racket/string
         (for-syntax racket/base))

(define-syntax-class literal
  (pattern
   (~or* expr:boolean
         expr:char
         expr:string
         expr:bytes
         expr:number
         expr:regexp
         expr:byte-regexp
         expr:vector-literal
         expr:box-literal
         expr:prefab-literal
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
  (pattern (arg:expr ...)
    #:with args #'(arg ...)
    #:attr arity (length (syntax->list #'args))))

(define-syntax-class clause
  (pattern expr:expr))

(define-syntax-class vector-literal
  (pattern #(_ ...)))

(define-syntax-class box-literal
  (pattern #&v))

(define-syntax-class prefab-literal
  (pattern e:expr
    #:when (prefab-struct-key (syntax-e #'e))))

(define-syntax-class (starts-with pfx)
  (pattern i:id
    #:when (string-prefix?
            (symbol->string
             (syntax-e #'i))
            pfx)))

;; A datatype used at compile time to convey user-defined data through
;; the various stages of compilation for the purposes of extending Qi
;; deforestation to custom list operations. It is currently used to
;; convey a Racket runtime for macros in qi/list through to the code
;; generation stage of Qi compilation (and could be used by any similar
;; "deep" macros written by users).
(struct deforestable-info [codegen])
