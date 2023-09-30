#lang racket/base

(provide tests)

(require (for-template qi/flow/core/compiler)
         rackunit
         rackunit/text-ui
         (only-in math sqr))

(define tests
  (test-suite
   "compiler tests"

   (test-suite
    "deforestation"
    ;; (~>> values (filter odd?) (map sqr) values)
    (check-equal? (syntax->datum
                   (deforest-rewrite
                     #'(thread (#%partial-application
                                ((#%host-expression filter)
                                 (#%host-expression odd?))))))
                  '(thread
                    (esc
                     (λ (lst)
                       ((cstream->list (inline-compose1 (filter-cstream-next odd?) list->cstream-next)) lst))))
                  "deforestation of map -- note this tests the rule in isolation; with normalization this would never be necessary")
    (check-equal? (syntax->datum
                   (deforest-rewrite
                     #'(thread (#%partial-application
                                ((#%host-expression map)
                                 (#%host-expression sqr))))))
                  '(thread
                    (esc
                     (λ (lst)
                       ((cstream->list (inline-compose1 (map-cstream-next sqr) list->cstream-next)) lst))))
                  "deforestation of filter -- note this tests the rule in isolation; with normalization this would never be necessary")
    (check-equal? (syntax->datum
                   (deforest-rewrite
                     #'(thread values
                               (#%partial-application
                                ((#%host-expression filter)
                                 (#%host-expression odd?)))
                               (#%partial-application
                                ((#%host-expression map)
                                 (#%host-expression sqr)))
                               values)))
                  '(thread
                    values
                    (esc
                     (λ (lst)
                       ((cstream->list
                         (inline-compose1
                          (map-cstream-next
                           sqr)
                          (filter-cstream-next
                           odd?)
                          list->cstream-next))
                        lst)))
                    values)
                  "deforestation in arbitrary positions")
    (check-equal? (syntax->datum
                   (deforest-rewrite
                     #'(thread (#%partial-application
                                ((#%host-expression map)
                                 (#%host-expression string-upcase)))
                               (#%partial-application
                                ((#%host-expression foldl)
                                 (#%host-expression string-append)
                                 (#%host-expression "I"))))))
                  '(thread
                    values
                    (esc
                     (λ (lst)
                       ((cstream->list
                         (inline-compose1
                          (map-cstream-next
                           sqr)
                          (filter-cstream-next
                           odd?)
                          list->cstream-next))
                        lst)))
                    values)
                  "deforestation in arbitrary positions"))
   (test-suite
    "fixed point"
    null)))

(module+ main
  (void (run-tests tests)))
