#lang racket/base

(provide tests)

(require qi/flow/core/util
         rackunit
         rackunit/text-ui
         syntax/parse
         (only-in racket/function
                  curryr))

(define-syntax-rule (test-syntax-equal? name a b)
  (test-equal? name
               (syntax->datum a)
               (syntax->datum b)))

(define tests
  (test-suite
   "Compiler utilities tests"

   (test-suite
    "fixed point"
    (check-equal? ((fix abs) -1) 1)
    (check-equal? ((fix abs) -1) 1)
    (let ([integer-div2 (compose floor (curryr / 2))])
      (check-equal? ((fix integer-div2) 10)
                    0)))
   (test-suite
    "find-and-map/qi"
    (test-syntax-equal? "top level"
                        (find-and-map/qi
                         (syntax-parser [(~datum b) #'q]
                                        [_ #f])
                         #'(a b c))
                        #'(a q c))
    (test-syntax-equal? "nested"
                        (find-and-map/qi
                         (syntax-parser [(~datum b) #'q]
                                        [_ #f])
                         #'(a (b c) d))
                        #'(a (q c) d))
    (test-syntax-equal? "multiple matches"
                        (find-and-map/qi
                         (syntax-parser [(~datum b) #'q]
                                        [_ #f])
                         #'(a b c b d))
                        #'(a q c q d))
    (test-syntax-equal? "multiple nested matches"
                        (find-and-map/qi
                         (syntax-parser [(~datum b) #'q]
                                        [_ #f])
                         #'(a (b c) (b d)))
                        #'(a (q c) (q d)))
    (test-syntax-equal? "no match"
                        (find-and-map/qi
                         (syntax-parser [(~datum b) #'q]
                                        [_ #f])
                         #'(a c d))
                        #'(a c d))
    ;; TODO: review this, it does not transform multi-level matches.
    ;; Are there cases where we would need this?
    (test-syntax-equal? "matches at muliple levels"
                        (find-and-map/qi
                         (syntax-parser [((~datum a) b ...) #'(b ...)]
                                        [_ #f])
                         #'(a c (a d e)))
                        #'(c (a d e)))
    (test-syntax-equal? "does not enter host expressions"
                        (find-and-map/qi
                         (syntax-parser [(~datum b) #'q]
                                        [_ #f])
                         #'(a (#%host-expression (b c)) d))
                        #'(a (#%host-expression (b c)) d))
    (test-syntax-equal? "toplevel host expression"
                        (find-and-map/qi
                         (syntax-parser [(~datum b) #'q]
                                        [_ #f])
                         #'(#%host-expression (b c)))
                        #'(#%host-expression (b c))))))

(module+ main
  (void (run-tests tests)))
