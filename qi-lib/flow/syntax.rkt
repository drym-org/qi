#lang racket/base

(provide sep-form
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

(require syntax/parse)

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
   (~or* (~datum △) (~datum sep)))
  (pattern
   ((~or* (~datum △) (~datum sep)) arg ...)))

(define-syntax-class select-form
  (pattern
   ((~datum select) arg ...)))

(define-syntax-class block-form
  (pattern
   ((~datum block) arg ...)))

(define-syntax-class group-form
  (pattern
   (~datum group))
  (pattern
   ((~datum group) arg ...)))

(define-syntax-class switch-form
  (pattern
   ((~datum switch) arg ...)))

(define-syntax-class sieve-form
  (pattern
   (~datum sieve))
  (pattern
   ((~datum sieve) arg ...)))

(define-syntax-class partition-form
  (pattern
   ({~datum partition} arg ...)))

(define-syntax-class try-form
  (pattern
   ((~datum try) arg ...)))

(define-syntax-class input-alias
  (pattern
   (~or* (~datum 1>)
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
   ((~datum if) arg ...)))

(define-syntax-class fanout-form
  (pattern
   (~datum fanout))
  (pattern
   ((~datum fanout) arg ...)))

(define-syntax-class feedback-form
  (pattern
   (~datum feedback))
  (pattern
   ((~datum feedback) arg ...)))

(define-syntax-class side-effect-form
  (pattern
   ((~or* (~datum ε) (~datum effect)) arg ...)))

(define-syntax-class amp-form
  (pattern
   (~or* (~datum ><) (~datum amp)))
  (pattern
   ((~or* (~datum ><) (~datum amp)) arg ...)))

(define-syntax-class pass-form
  (pattern
   (~datum pass))
  (pattern
   ((~datum pass) arg ...)))

(define-syntax-class fold-left-form
  (pattern
   (~datum >>))
  (pattern
   ((~datum >>) arg ...)))

(define-syntax-class fold-right-form
  (pattern
   (~datum <<))
  (pattern
   ((~datum <<) arg ...)))

(define-syntax-class loop-form
  (pattern
   ((~datum loop) arg ...)))

(define-syntax-class blanket-template-form
  ;; "prarg" = "pre-supplied argument"
  (pattern
   (natex prarg-pre ... (~datum __) prarg-post ...)))

(define-syntax-class and%-form
  (pattern
   ((~datum and%) arg ...)))

(define-syntax-class or%-form
  (pattern
   ((~datum or%) arg ...)))

(define-syntax-class right-threading-form
  (pattern
   ((~or* (~datum ~>>) (~datum thread-right)) arg ...)))

(define-syntax-class clos-form
  (pattern
   (~datum clos))
  (pattern
   ((~datum clos) arg ...)))
