#lang racket/base

(provide (for-syntax normalize-pass))

(require (for-syntax racket/base
                     syntax/parse
                     "strategy.rkt"
                     "private/form-property.rkt")
         "passes.rkt")

;; 0. "Qi-normal form"
(begin-for-syntax
  (define (normalize-rewrite stx)
    (syntax-parse stx
      #:datum-literals (#%host-expression
                        #%blanket-template
                        #%fine-template
                        esc
                        gen
                        thread
                        pass
                        if
                        amp
                        relay
                        tee
                        sep
                        collect
                        __)

      ;; "deforestation" for values
      ;; (~> (pass f) (>< g)) → (>< (if f g ⏚))
      [(thread _0 ... (pass f) (amp g) _1 ...)
       #'(thread _0 ... (amp (if f g ground)) _1 ...)]
      ;; merge pass filters in sequence
      [(thread _0 ... (pass f) (pass g) _1 ...)
       #'(thread _0 ... (pass (and f g)) _1 ...)]
      ;; collapse deterministic conditionals
      [(if (gen (#%host-expression (~datum #t)))
           f
           g)
       #'f]
      [(if (gen (#%host-expression (~datum #f)))
           f
           g)
       #'g]
      ;; trivial threading form
      [(thread f)
       #'f]
      ;; associative laws for ~>
      [(thread _0 ... (thread f ...) _1 ...) ; note: greedy matching
       #'(thread _0 ... f ... _1 ...)]
      ;; left and right identity for ~>
      [(thread _0 ... (~datum _) _1 ...)
       #'(thread _0 ... _1 ...)]
      ;; composition of identity flows is the identity flow
      [(thread (~datum _) ...)
       #'_]
      ;; amp and identity
      [(amp (~datum _))
       #'_]
      ;; trivial tee junction
      [(tee f)
       #'f]
      ;; merge adjacent gens in a tee junction
      [(tee _0 ... (gen a ...) (gen b ...) _1 ...)
       #'(tee _0 ... (gen a ... b ...) _1 ...)]
      ;; dead gen elimination
      [(thread _0 ... (gen a ...) (gen b ...) _1 ...)
       #'(thread _0 ... (gen b ...) _1 ...)]
      ;; prism identities
      ;; Note: (~> ... △ ▽ ...) can't be rewritten to `values` since that's
      ;; only valid if the input is in fact a list, and is an error otherwise,
      ;; and we can only know this at runtime.
      [(thread _0 ... collect sep _1 ...)
       #'(thread _0 ... _1 ...)]
      ;; collapse `values` inside a threading form
      [(thread _0 ... (esc (#%host-expression (~literal values))) _1 ...)
       #'(thread _0 ... _1 ...)]
      [(#%blanket-template (hex __))
       #'(esc hex)]
      ;; return syntax unchanged if there are no applicable normalizations
      [_ stx]))

  (define-and-register-pass 10 (normalize-pass stx)
    (attach-form-property
     (find-and-map/qi
      (fix normalize-rewrite)
      stx))))
