#lang racket/base

(provide tests)

(require qi
         rackunit
         (only-in math sqr)
         racket/function)

(define tests
  (test-suite
   "threading tests"
   (test-suite
    "Edge/base cases"
    (check-equal? (~> ()) (void))
    (check-equal? (~>> ()) (void))
    (check-equal? (~> () (const 5)) 5)
    (check-equal? (~>> () (const 5)) 5)
    ;; when no functions to thread through are provided,
    ;; we could either (1) return void, (2) return no values
    ;; at all, or (3) return the input values themselves.
    ;; the standard threading behavior does (3)
    ;; while at the moment the present form does (1)
    (check-equal? (~> (4)) (void))
    (check-equal? (~>> (4)) (void))
    (check-equal? (~> (4 5 6)) (void))
    (check-equal? (~>> (4 5 6)) (void)))
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
