#lang racket/base

(provide tests)

(require qi
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         (only-in adjutor values->list)
         racket/function)

(define on-tests
  (test-suite
   "on tests"
   (test-suite
    "Edge/base cases"
    (check-equal? (on (0))
                  0
                  "no clauses, unary")
    (check-equal? (values->list (on (5 5)))
                  (list 5 5)
                  "no clauses, binary")
    (check-equal? (on ()
                    (const 3))
                  3
                  "no arguments"))
   (test-suite
    "smoke tests"
    (check-equal? (on (2) add1) 3)
    (check-equal? (on (2) (~> sqr add1)) 5)
    (check-equal? (on (2 3) (~> (>< sqr) +)) 13)
    (check-true (on (2) (eq? 2)))
    (check-true (on (2 -3) (and% positive? negative?)))
    (check-equal? (on (2) (if positive? add1 sub1)) 3))))

(define flow-lambda-tests
  (test-suite
   "flow-lambda tests"
   (test-suite
    "header tests"
    (check-equal? ((flow-lambda a* _)
                   1 2 3 4)
                  '(1 2 3 4))
    (check-equal? ((flow-lambda (a . a*) list)
                   1 2 3 4)
                  '(1 (2 3 4))))))

(define define-flow-tests
  (test-suite
   "define-flow tests"
   (test-suite
    "header tests"
    (check-equal? (let ()
                    (define-flow ((t n) . n*)
                      (~>> (memq n)))
                    (list ((t 3) 1 2 3)
                          ((t 0) 1 2 3)))
                  '((3) #f)))))

(define tests
  (test-suite
   "on.rkt tests"
   on-tests
   flow-lambda-tests
   define-flow-tests))

(module+ main
  (void (run-tests tests)))
