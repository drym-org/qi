#lang racket/base

(provide tests)

(require (for-syntax racket/base)
         ;; necessary to recognize and expand core forms correctly
         qi/flow/extended/expander
         ;; necessary to correctly expand the right-threading form
         qi/flow/extended/forms
         rackunit
         rackunit/text-ui
         syntax/macro-testing
         qi/flow/core/compiler
         qi/list
         "private/deforest-util.rkt"
         (submod qi/flow/extended/expander invoke))

(begin-for-syntax
  ;; A function that expands and compiles surface syntax
  (define (qi-compile stx)
    (compile-flow
     (expand-flow stx))))


(define tests

  (test-suite
   "full cycle tests"

   (test-suite
    "multiple passes"
    (test-true "normalize → deforest"
               (deforested?
                 (phase1-eval
                  (qi-compile
                   #'(~>> (filter odd?) values (map sqr))))))
    ;; We expect the Qi expander to translate threading direction simply to
    ;; chirality of individual contained forms (indicated by the presence of
    ;; a blanket template on either side) if they are applications of host
    ;; language functions, and to leave them unchanged if they are syntactic
    ;; forms (where chirality is irrelevant). We also expect normalization
    ;; to collapse nested threading forms, so that the following should be
    ;; deforested.
    (test-true "nested, different threading direction"
               (deforested? (phase1-eval
                             (qi-compile
                              #'(~> (filter odd?) (~>> (map sqr))))))))))

(module+ main
  (void
   (run-tests tests)))
