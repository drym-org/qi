#lang racket/base

(provide tests)

(require (for-syntax racket/base)
         rackunit
         rackunit/text-ui
         racket/function
         ;; necessary to recognize and expand core forms correctly
         qi/flow/extended/expander
         ;; necessary to correctly expand the right-threading form
         qi/flow/extended/forms
         (submod qi/flow/extended/expander invoke)
         qi/flow/core/compiler
         (for-template qi/flow/core/compiler)
         qi/on)

;; NOTE: we may need to tag test syntax with `tag-form-syntax`
;; in some cases. See the comment on that function definition.
;; It's not necessary if we are directly using the expander
;; output, as that already includes the property, but we might
;; need to reattach it if we tranform that syntax in some way.

(define (runs-within-time? f timeout)
  (define handle (thread f))
  (define result (sync/timeout timeout handle))
  (kill-thread handle) ; no-op if already dead
  (not (not result)))

(define tests

  (test-suite
   "inlining"

   (test-suite
    "does not inline and enter infinite loop"
    (test-true "does not enter infinite loop"
               (runs-within-time?
                (thunk
                 (expand
                  #'(let ()
                      (define-flow f (if odd? (~> add1 f) _))
                      (f 4))))
                1.0)))))

(module+ main
  (void
   (run-tests tests)))
