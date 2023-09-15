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
                  "deforestation in arbitrary positions"))))

(module+ main
  (void (run-tests tests)))
