#lang racket/base

(provide literal
         subject
         clause
         starts-with
         sep-form
         select-form
         block-form
         group-form
         switch-form
         sieve-form
         partition-form
         try-form
         fanout-form
         feedback-form
         side-effect-form
         amp-form
         input-alias
         if-form
         pass-form
         fold-left-form
         fold-right-form
         loop-form
         blanket-template-form
         and%-form
         or%-form
         right-threading-form
         clos-form)

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

#|
These syntax classes are used in the flow macro to handle matching of
the input syntax to valid Qi syntax. Typically, _matching_ is the only
function these syntax classes fulfill, and once matched, the input
syntax is typically handed over to dedicated parsers that
independently parse and expand the input. It's done this way to keep
the clauses of the flow macro specific to individual forms, instead of
these forms appearing in multiple clauses, so that the code for each
form is decoupled from the rest of the flow macro.

See comments in flow.rkt for more details.
|#

(define-syntax-class sep-form
  (pattern
   (~or (~datum △) (~datum sep)))
  (pattern
   ((~or (~datum △) (~datum sep)) onex:clause)))

(define-syntax-class select-form
  (pattern
   ((~datum select) arg ...)))

(define-syntax-class block-form
  (pattern
   ((~datum block) arg ...)))

(define-syntax-class group-form
  (pattern
   ((~datum group) n:expr
                   selection-onex:clause
                   remainder-onex:clause))
  (pattern
   (~datum group))
  (pattern
   ((~datum group) arg ...)))

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
   ((~datum sieve) condition:clause
                   sonex:clause
                   ronex:clause))
  (pattern
   (~datum sieve))
  (pattern
   ((~datum sieve) arg ...)))

(define-syntax-class partition-form
  (pattern
   ({~datum partition}))
  (pattern
   ({~datum partition} [cond:clause body:clause]))
  (pattern
   ({~datum partition} [cond:clause body:clause]  ...+)))

(define-syntax-class try-form
  (pattern
   ((~datum try) flo
                 [error-condition-flo error-handler-flo]
                 ...+))
  (pattern
   ((~datum try) arg ...)))

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

(define-syntax-class if-form
  (pattern
   ((~datum if) consequent:clause
                alternative:clause))
  (pattern
   ((~datum if) condition:clause
                consequent:clause
                alternative:clause)))

(define-syntax-class fanout-form
  (pattern
   (~datum fanout))
  (pattern
   ((~datum fanout) n:number))
  (pattern
   ((~datum fanout) n:expr)))

(define-syntax-class feedback-form
  (pattern
   ((~datum feedback) ((~datum while) tilex:clause)
                      ((~datum then) thenex:clause)
                      onex:clause))
  (pattern
   ((~datum feedback) ((~datum while) tilex:clause) onex:clause))
  (pattern
   ((~datum feedback) n:expr
                      ((~datum then) thenex:clause)
                      onex:clause))
  (pattern
   ((~datum feedback) n:expr onex:clause))
  (pattern
   (~datum feedback)))

(define-syntax-class side-effect-form
  (pattern
   ((~or (~datum ε) (~datum effect)) sidex:clause onex:clause))
  (pattern
   ((~or (~datum ε) (~datum effect)) sidex:clause)))

(define-syntax-class amp-form
  (pattern
   (~or (~datum ><) (~datum amp)))
  (pattern
   ((~or (~datum ><) (~datum amp)) onex:clause))
  (pattern
   ((~or (~datum ><) (~datum amp)) onex0:clause onex:clause ...)))

(define-syntax-class pass-form
  (pattern
   (~datum pass))
  (pattern
   ((~datum pass) onex:clause)))

(define-syntax-class fold-left-form
  (pattern
   (~datum >>))
  (pattern
   ((~datum >>) fn init))
  (pattern
   ((~datum >>) fn)))

(define-syntax-class fold-right-form
  (pattern
   (~datum <<))
  (pattern
   ((~datum <<) fn init))
  (pattern
   ((~datum <<) fn)))

(define-syntax-class loop-form
  (pattern
   ((~datum loop) pred:clause mapex:clause combex:clause retex:clause))
  (pattern
   ((~datum loop) pred:clause mapex:clause combex:clause))
  (pattern
   ((~datum loop) pred:clause mapex:clause))
  (pattern
   ((~datum loop) mapex:clause)))

(define-syntax-class blanket-template-form
  ;; "prarg" = "pre-supplied argument"
  (pattern
   (natex prarg-pre ... (~datum __) prarg-post ...)))

(define-syntax-class and%-form
  (pattern
   ((~datum and%) onex:clause ...)))

(define-syntax-class or%-form
  (pattern
   ((~datum or%) onex:clause ...)))

(define-syntax-class right-threading-form
  (pattern
   ((~or (~datum ~>>) (~datum thread-right)) onex:clause ...)))

(define-syntax-class clos-form
  (pattern
   ((~datum clos) onex:clause)))
