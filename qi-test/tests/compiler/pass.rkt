#lang racket/base

(provide tests)

(require qi/flow/core/pass
         rackunit
         rackunit/text-ui
         syntax/parse
         syntax/parse/define
         (for-syntax racket/base)
         (only-in qi/flow/core/private/form-property tag-form-syntax)
         (only-in racket/function
                  curry
                  curryr
                  thunk*))

;; NOTE: we need to tag test syntax with `tag-form-syntax`
;; in most cases. See the comment on that function definition.

;; traverse syntax a and map it under the indicated parser patterns
;; using find-and-map/qi, and verify it results in syntax b
(define-syntax-parser test-syntax-map-equal?
  [(_ name (pat ...) a b)
   #:with f #'(syntax-parser pat ...)
   #'(test-equal? name
                  (syntax->datum
                   (find-and-map/qi f (tag-form-syntax a)))
                  (syntax->datum b))])

(define tests
  (test-suite
   "Compiler pass utilities tests"

   (test-suite
    "fixed point"
    (check-equal? ((fix abs) -1) 1)
    (check-equal? ((fix abs) -1) 1)
    (let ([integer-div2 (compose floor (curryr / 2))])
      (check-equal? ((fix integer-div2) 10)
                    0))
    (check-equal? ((fix (thunk* #f)) -1)
                  -1
                  "false return value terminates fixed-point finding"))
   (test-suite
    "find-and-map/qi"
    (test-syntax-map-equal? "top level"
                            ([(~datum b) #'q]
                             [_ this-syntax])
                            #'(a b c)
                            #'(a q c))
    (test-syntax-map-equal? "does not explore node on false return value"
                            ([((~datum stop) e ...) #f]
                             [(~datum b) #'q]
                             [_ this-syntax])
                            #'(a b (stop c b))
                            #'(a q (stop c b)))
    (test-syntax-map-equal? "nested"
                            ([(~datum b) #'q]
                             [_ this-syntax])
                            #'(a (b c) d)
                            #'(a (q c) d))
    (test-syntax-map-equal? "multiple matches"
                            ([(~datum b) #'q]
                             [_ this-syntax])
                            #'(a b c b d)
                            #'(a q c q d))
    (test-syntax-map-equal? "multiple nested matches"
                            ([(~datum b) #'q]
                             [_ this-syntax])
                            #'(a (b c) (b d))
                            #'(a (q c) (q d)))
    (test-syntax-map-equal? "no match"
                            ([(~datum b) #'q]
                             [_ this-syntax])
                            #'(a c d)
                            #'(a c d))
    ;; TODO: review this, it does not transform multi-level matches.
    ;; See a TODO in tests/compiler/rules.rkt for a case where we would need it
    (test-syntax-map-equal? "matches at multiple levels"
                            ([((~datum a) b ...) #'(b ...)]
                             [_ this-syntax])
                            #'(a c (a d e))
                            #'(c (a d e)))
    (test-syntax-map-equal? "does not match spliced"
                            ([((~datum a) b ...) #'(b ...)]
                             [_ this-syntax])
                            #'(c a b d e)
                            #'(c a b d e))
    (test-syntax-map-equal? "does not enter host expressions"
                            ([(~datum b) #'q]
                             [_ this-syntax])
                            #'(a (#%host-expression (b c)) d)
                            #'(a (#%host-expression (b c)) d))
    (test-syntax-map-equal? "toplevel host expression"
                            ([(~datum b) #'q]
                             [_ this-syntax])
                            #'(#%host-expression (b c))
                            #'(#%host-expression (b c))))))

(module+ main
  (void
   (run-tests tests)))
