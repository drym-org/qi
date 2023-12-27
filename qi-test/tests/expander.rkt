#lang racket/base

(provide tests)

(require (for-syntax racket/base
                     qi/flow/extended/syntax)
         (submod qi/flow/extended/expander invoke)
         syntax/macro-testing
         racket/base
         qi/flow/extended/expander
         qi/flow/extended/util
         rackunit
         rackunit/text-ui)

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

   (test-suite
    "rules"
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
                                   __)))))))
   (test-suite
    "utils"
    ;; this is just temporary until we properly track source expressions through
    ;; expansion, so it doesn't match all the nuances of the core language grammar
    (test-equal? "de-expansion"
                 (syntax->datum
                  (datum->syntax #f
                    (map prettify-flow-syntax
                         '(flow  (gen (#%host-expression f))
                                 ground
                                 (select 1 2)
                                 (amp (esc (#%host-expression f)))
                                 (relay (esc (#%host-expression f)) (esc (#%host-expression g)))
                                 (tee (esc (#%host-expression f)) (esc (#%host-expression g)))
                                 (thread (esc (#%host-expression f)) (esc (#%host-expression g)))
                                 (gen (#%host-expression 2) (#%host-expression 3))
                                 (pass (esc (#%host-expression f)))
                                 (sep (esc (#%host-expression g)))
                                 (and (esc (#%host-expression f)) (or (esc (#%host-expression g)) (not (esc (#%host-expression h)))))
                                 (all (esc (#%host-expression f)))
                                 (any (esc (#%host-expression f)))
                                 (fanout (#%host-expression 2))
                                 (group (#%host-expression a) (esc (#%host-expression b)) (esc (#%host-expression c)))
                                 (if (esc (#%host-expression a)) (esc (#%host-expression f)))
                                 (sieve (esc (#%host-expression a)) (esc (#%host-expression b)) (esc (#%host-expression c)))
                                 (partition ((esc (#%host-expression a)) (esc (#%host-expression b)))
                                            ((esc (#%host-expression c)) (esc (#%host-expression d))))
                                 (try (esc (#%host-expression q))
                                   ((esc (#%host-expression a)) (esc (#%host-expression b)))
                                   ((esc (#%host-expression c)) (esc (#%host-expression d))))
                                 (>> (esc (#%host-expression f)))
                                 (<< (esc (#%host-expression f)))
                                 (feedback (while (esc (#%host-expression f))))
                                 (loop (esc (#%host-expression f)))
                                 (loop2 (esc (#%host-expression f)) (esc (#%host-expression a)) (esc (#%host-expression f)))
                                 (clos (esc (#%host-expression f)))
                                 (esc (#%host-expression f))
                                 (#%blanket-template ((#%host-expression 1) __ (#%host-expression 4)))
                                 (#%blanket-template ((#%host-expression 4) __))
                                 (#%fine-template ((#%host-expression 4) _))))))
                 '(flow  (gen f)
                         ground
                         (select 1 2)
                         (>< f)
                         (== f g)
                         (-< f g)
                         (~> f g)
                         (gen 2 3)
                         (pass f)
                         (sep g)
                         (and f (or g (not h)))
                         (all f)
                         (any f)
                         (fanout 2)
                         (group a b c)
                         (if a f)
                         (sieve a b c)
                         ;; partition and try are actually jumbled
                         (partition (a b) (c d))
                         (try q (a b) (c d))
                         (>> f)
                         (<< f)
                         ;; feedback grammar not handled - it's just a hack anyway
                         (feedback (while (esc (#%host-expression f))))
                         (loop f)
                         (loop2 f a f)
                         (clos f)
                         f
                         (1 __ 4)
                         (4 __)
                         (4 _))))))

(module+ main
  (void
   (run-tests tests)))
