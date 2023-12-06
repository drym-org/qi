#lang racket/base

(provide normalize-rewrite)

(require syntax/parse)

;; 0. "Qi-normal form"
(define (normalize-rewrite stx)
  (syntax-parse stx
    ;; "deforestation" for values
    ;; (~> (pass f) (>< g)) → (>< (if f g ⏚))
    [((~datum thread) _0 ... ((~datum pass) f) ((~datum amp) g) _1 ...)
     #'(thread _0 ... (amp (if f g ground)) _1 ...)]
    ;; merge amps in sequence
    [((~datum thread) _0 ... ((~datum amp) f) ((~datum amp) g) _1 ...)
     #'(thread _0 ... (amp (thread f g)) _1 ...)]
    ;; merge pass filters in sequence
    [((~datum thread) _0 ... ((~datum pass) f) ((~datum pass) g) _1 ...)
     #'(thread _0 ... (pass (and f g)) _1 ...)]
    ;; collapse deterministic conditionals
    [((~datum if) (~datum #t) f g) #'f]
    [((~datum if) (~datum #f) f g) #'g]
    ;; trivial threading form
    [((~datum thread) f)
     #'f]
    ;; associative laws for ~>
    [((~datum thread) _0 ... ((~datum thread) f ...) _1 ...) ; note: greedy matching
     #'(thread _0 ... f ... _1 ...)]
    ;; left and right identity for ~>
    [((~datum thread) _0 ... (~datum _) _1 ...)
     #'(thread _0 ... _1 ...)]
    ;; composition of identity flows is the identity flow
    [((~datum thread) (~datum _) ...)
     #'_]
    ;; identity flows composed using a relay
    [((~datum relay) (~datum _) ...)
     #'_]
    ;; amp and identity
    [((~datum amp) (~datum _))
     #'_]
    ;; trivial tee junction
    [((~datum tee) f)
     #'f]
    ;; merge adjacent gens in a tee junction
    [((~datum tee) _0 ... ((~datum gen) a ...) ((~datum gen) b ...) _1 ...)
     #'(tee _0 ... (gen a ... b ...) _1 ...)]
    ;; dead gen elimination
    [((~datum thread) _0 ... ((~datum gen) a ...) ((~datum gen) b ...) _1 ...)
     #'(thread _0 ... (gen b ...) _1 ...)]
    ;; prism identities
    ;; Note: (~> ... △ ▽ ...) can't be rewritten to `values` since that's
    ;; only valid if the input is in fact a list, and is an error otherwise,
    ;; and we can only know this at runtime.
    [((~datum thread) _0 ... (~datum collect) (~datum sep) _1 ...)
     #'(thread _0 ... _1 ...)]
    ;; collapse `values` and `_` inside a threading form
    [((~datum thread) _0 ... (~literal values) _1 ...)
     #'(thread _0 ... _1 ...)]
    [((~datum thread) _0 ... (~datum _) _1 ...)
     #'(thread _0 ... _1 ...)]
    [((~datum #%blanket-template) (hex (~datum __)))
     #'hex]
    ;; return syntax unchanged if there are no applicable normalizations
    [_ stx]))
