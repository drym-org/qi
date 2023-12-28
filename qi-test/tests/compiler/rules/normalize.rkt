#lang racket/base

(provide tests)

(require (for-template qi/flow/core/compiler)
         ;; necessary to recognize and expand core forms correctly
         qi/flow/extended/expander
         (for-syntax racket/base)
         rackunit
         rackunit/text-ui
         qi/flow/core/private/form-property
         "../private/expand-util.rkt"
         syntax/parse/define)

;; NOTE: we need to tag test syntax with `tag-form-syntax`
;; in most cases. See the comment on that function definition.

(define-syntax-parse-rule (test-normalize name a b ...+)
  (begin
    (test-equal? name
                 (syntax->datum
                  (normalize-pass
                   (tag-form-syntax ; should not be necessary
                    (phase0-expand-flow a))))
                 (syntax->datum
                  (normalize-pass
                   (tag-form-syntax ; should not be necessary
                    (phase0-expand-flow b)))))
    ...))


(define tests

  (test-suite
   "normalization"

   (test-suite
    "equivalence of normalized expressions"
    (test-normalize "pass-amp deforestation"
                    #'(~>
                       (pass f)
                       (>< g))
                    #'(>< (if f g ground)))
    (test-normalize "merge pass filters in sequence"
                    #'(~> (pass f) (pass g))
                    #'(pass (and f g)))
    (test-normalize "collapse deterministic conditionals"
                    #'(if #t f g)
                    #'f)
    (test-normalize "collapse deterministic conditionals"
                    #'(if #f f g)
                    #'g)
    (test-normalize "trivial threading is collapsed"
                    #'(~> f)
                    #'f)
    (test-normalize "associative laws for ~>"
                    #'(~> f (~> g h) i)
                    #'(~> f g (~> h i))
                    #'(~> (~> f g) h i)
                    #'(~> f g h i))
    (test-normalize "left and right identity for ~>"
                    #'(~> f _)
                    #'(~> _ f)
                    #'f)
    (test-normalize "line composition of identity flows"
                    #'(~> _ _ _)
                    #'(~> _ _)
                    #'(~> _)
                    #'_)
    (test-normalize "amp under identity"
                    #'(>< _)
                    #'_)
    (test-normalize "trivial tee junction"
                    #'(-< f)
                    #'f)
    (test-normalize "merge adjacent gens in a tee junction"
                    #'(-< (gen a b) (gen c d))
                    #'(-< (gen a b c d)))
    (test-normalize "remove dead gen in a line"
                    #'(~> (gen a b) (gen c d))
                    #'(~> (gen c d)))
    (test-normalize "prism identities"
                    #'(~> ▽ △)
                    #'_)
    (test-normalize "redundant blanket template"
                    #'(f __)
                    #'f)
    (test-normalize "values is collapsed inside ~>"
                    #'(~> values f values)
                    #'(~> f))
    ;; TODO: this test reveals a case that should be
    ;; rewritten but isn't. Currently, once there is a
    ;; match at one level during tree traversal
    ;; (in find-and-map), we do not traverse the expression
    ;; further.
    ;; (test-normalize "multiple levels of normalization"
    ;;                 #'(~> (>< (~> f)))
    ;;                 #'(>< f))
    (test-normalize "_ is collapsed inside ~>"
                    #'(~> _ f _)
                    #'f)
    (test-normalize "nested positions"
                    #'(>< (>< (~> _ f _)))
                    #'(>< (>< f)))
    (test-normalize "multiple independent positions"
                    #'(-< (~> _ f _) (~> (~> f g)))
                    #'(-< f (~> f g))))

   (test-suite
    "specific output"
    (test-equal? "weird bug"
                 (syntax->datum
                  (normalize-pass #'(thread tee collect)))
                 (syntax->datum
                  #'(thread tee collect))))))

(module+ main
  (void
   (run-tests tests)))
