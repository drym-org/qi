#lang racket/base

(provide tests)

(require (for-syntax racket/base
                     qi/flow/extended/syntax)
         syntax/macro-testing
         syntax-spec-v1
         racket/base
         qi/flow/extended/expander
         rackunit
         rackunit/text-ui)

(begin-for-syntax
  (define (expand-flow stx)
    ((nonterminal-expander closed-floe) stx)))

;; TODO: these tests compare syntax as datums, but that's not sufficient
;; since the identifiers used may be bound differently which would affect
;; e.g. literal pattern matching.
;; To do it correctly, we need an alpha-equivalence predicate for Core Qi
;; that possibly delegates to a similar predicate for any Racket
;; subexpressions. This could be a predicate that syntax-spec could
;; infer, but it's unclear at this time.
(define tests
  (test-suite
   "expander tests"

   (test-true "basic expansion"
              (phase1-eval
               (equal? (syntax->datum
                        (expand-flow #'(~> sqr add1)))
                       '(thread (esc (#%host-expression sqr))
                                (esc (#%host-expression add1))))))

   (test-true "single core form (if)"
              (phase1-eval
               (equal? (syntax->datum
                        (expand-flow #'(if p c a)))
                       '(if (esc (#%host-expression p))
                            (esc (#%host-expression c))
                            (esc (#%host-expression a))))))

   (test-true "mix of core forms"
              (phase1-eval
               (equal? (syntax->datum
                        (expand-flow #'(thread (amp a)
                                               (relay b c)
                                               (tee d e))))
                       '(thread
                         (amp (esc (#%host-expression a)))
                         (relay (esc (#%host-expression b)) (esc (#%host-expression c)))
                         (tee (esc (#%host-expression d)) (esc (#%host-expression e)))))))

   (test-true "undecorated functions are escaped"
              (phase1-eval
               (equal? (syntax->datum
                        (expand-flow #'f))
                       '(esc (#%host-expression f)))))

   (test-true "literal is expanded to an explicit use of the gen core form"
              (phase1-eval
               (equal? (syntax->datum
                        (expand-flow #'5))
                       '(gen (#%host-expression 5)))))

   (test-true "fine template syntax expands to an explicit use of the #%fine-template core form"
              (phase1-eval
               (equal? (syntax->datum
                        (expand-flow #'(f _ a _ b)))
                       '(#%fine-template
                         ((#%host-expression f)
                          _
                          (#%host-expression a)
                          _
                          (#%host-expression b))))))

   (test-true "blanket template syntax expands to an explicit use of the #%blanket-template core form"
              (phase1-eval
               (equal? (syntax->datum
                        (expand-flow #'(f a __ b)))
                       '(#%blanket-template
                         ((#%host-expression f)
                          (#%host-expression a)
                          __
                          (#%host-expression b))))))

   (test-true "expand chiral forms to a use of a blanket template"
              (phase1-eval
               (equal? (syntax->datum
                        (expand-flow
                         (datum->syntax #f
                           (map make-right-chiral
                                (syntax->list
                                 #'(thread (f 1)))))))
                       '(thread (#%blanket-template
                                 ((#%host-expression f)
                                  (#%host-expression 1)
                                  __))))))))

(module+ main
  (void
   (run-tests tests)))
