#lang racket/base

(provide tests)

(require qi
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         (only-in adjutor values->list)
         racket/function
         syntax/macro-testing)

(define tests
  (test-suite
   "threading tests"
   (test-suite
    "Edge/base cases"
    (check-equal? (values->list (~> ())) null)
    (check-equal? (values->list (~>> ())) null)
    (check-equal? (~> () (gen 5)) 5)
    (check-equal? (~>> () (gen 5)) 5)
    (check-equal? (~> (4)) 4)
    (check-equal? (~>> (4)) 4)
    (check-equal? (values->list (~> (4 5 6))) '(4 5 6))
    (check-equal? (values->list (~>> (4 5 6))) '(4 5 6)))
   (test-suite
    "Syntax"
    (check-exn exn:fail?
               (thunk (convert-compile-time-error
                       (~> (1 2) sep)))
               "catch a common syntax error")
    (check-exn exn:fail?
               (thunk (convert-compile-time-error
                       (~>> (1 2) sep)))
               "catch a common syntax error"))
   (test-suite
    "smoke"
    (check-equal? (~> (3) sqr add1) 10)
    (check-equal? (~>> (3) sqr add1) 10)
    (check-equal? (~> (3 4) + number->string (string-append "a")) "7a")
    (check-equal? (~>> (3 4) + number->string (string-append "a")) "a7")
    (check-equal? (~> ((list 3 4 5)) △ (>< sqr) +) 50 "legitimate input to the sep form")
    (check-equal? (~>> ((list 3 4 5)) △ (>< sqr) +) 50 "legitimate input to the sep form")
    (check-equal? (~> (5 20 3)
                      (group 1
                             (~>
                              add1
                              sqr)
                             *)
                      (>< number->string)
                      (string-append "a:" _ "b:" _))
                  "a:36b:60"))))

(module+ main
  (void (run-tests tests)))
