#lang racket/base

(provide tests)

(require qi
         rackunit
         (only-in math sqr)
         (only-in adjutor values->list)
         racket/function)

(define tests
  (test-suite
   "threading tests"
   (test-suite
    "Edge/base cases"
    (check-equal? (values->list (~> ())) null)
    (check-equal? (values->list (~>> ())) null)
    (check-equal? (~> () (const 5)) 5)
    (check-equal? (~>> () (const 5)) 5)
    (check-equal? (~> (4)) 4)
    (check-equal? (~>> (4)) 4)
    (check-equal? (values->list (~> (4 5 6))) '(4 5 6))
    (check-equal? (values->list (~>> (4 5 6))) '(4 5 6)))
   (test-suite
    "smoke"
    (check-equal? (~> (3) sqr add1) 10)
    (check-equal? (~>> (3) sqr add1) 10)
    (check-equal? (~> (3 4) + number->string (string-append "a")) "7a")
    (check-equal? (~>> (3 4) + number->string (string-append "a")) "a7")
    (check-equal? (~> (5 20 3)
                      (group 1
                             (~>
                              add1
                              sqr)
                             *)
                      (>< number->string)
                      (string-append "a:" _ "b:" _))
                  "a:36b:60"))))
