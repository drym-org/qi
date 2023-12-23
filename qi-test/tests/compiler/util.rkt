#lang racket/base

(provide tests)

(require qi/flow/core/util
         rackunit
         rackunit/text-ui
         syntax/parse
         syntax/parse/experimental/template
         (only-in racket/function
                  curry
                  curryr
                  thunk*))

(define-syntax-rule (test-syntax-equal? name f a b)
  (test-equal? name
               (syntax->datum
                (find-and-map/qi f (tag-syntax a)))
               (syntax->datum b)))

(define (syntax-list? v)
  (and (syntax? v) (syntax->list v)))

(define (tree-map f tree)
  (cond [(list? tree) (map (curry tree-map f)
                           tree)]
        [(syntax-list? tree) (datum->syntax tree
                               (map (curry tree-map f)
                                    (syntax->list tree)))]
        [else (f tree)]))

(define (attach-form-property stx)
  (syntax-property stx 'nonterminal 'floe))

(define (tag-syntax stx)
  (tree-map attach-form-property stx))

(define tests
  (test-suite
   "Compiler utilities tests"

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
    (test-syntax-equal? "top level"
                        (syntax-parser [(~datum b) #'q]
                                       [_ this-syntax])
                        #'(a b c)
                        #'(a q c))
    (test-syntax-equal? "does not explore node on false return value"
                        (syntax-parser [((~datum stop) e ...) #f]
                                       [(~datum b) #'q]
                                       [_ this-syntax])
                        #'(a b (stop c b))
                        #'(a q (stop c b)))
    (test-syntax-equal? "nested"
                        (syntax-parser [(~datum b) #'q]
                                       [_ this-syntax])
                        #'(a (b c) d)
                        #'(a (q c) d))
    (test-syntax-equal? "multiple matches"
                        (syntax-parser [(~datum b) #'q]
                                       [_ this-syntax])
                        #'(a b c b d)
                        #'(a q c q d))
    (test-syntax-equal? "multiple nested matches"
                        (syntax-parser [(~datum b) #'q]
                                       [_ this-syntax])
                        #'(a (b c) (b d))
                        #'(a (q c) (q d)))
    (test-syntax-equal? "no match"
                        (syntax-parser [(~datum b) #'q]
                                       [_ this-syntax])
                        #'(a c d)
                        #'(a c d))
    ;; TODO: review this, it does not transform multi-level matches.
    ;; Are there cases where we would need this?
    (test-syntax-equal? "matches at multiple levels"
                        (syntax-parser [((~datum a) b ...) #'(b ...)]
                                       [_ this-syntax])
                        #'(a c (a d e))
                        #'(c (a d e)))
    (test-syntax-equal? "does not match spliced"
                        (syntax-parser [((~datum a) b ...) #'(b ...)]
                                       [_ this-syntax])
                        #'(c a b d e)
                        #'(c a b d e))
    (test-syntax-equal? "does not enter host expressions"
                        (syntax-parser [(~datum b) #'q]
                                       [_ this-syntax])
                        #'(a (#%host-expression (b c)) d)
                        #'(a (#%host-expression (b c)) d))
    (test-syntax-equal? "toplevel host expression"
                        (syntax-parser [(~datum b) #'q]
                                       [_ this-syntax])
                        #'(#%host-expression (b c))
                        #'(#%host-expression (b c))))))

(module+ main
  (void
   (run-tests tests)))
