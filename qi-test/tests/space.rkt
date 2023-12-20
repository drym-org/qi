#lang racket/base

(provide tests)

(require qi
         qi/flow/space
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         (for-syntax racket/base
                     syntax/parse))

(define tests
  (test-suite
   "qi binding space tests"

   (test-suite
    "define-for-qi"
    (let ()
      (define-for-qi abc 5)
      (test-equal? "define and reference in qi space"
                   (reference-qi abc)
                   5))
    (let ()
      (define-for-qi (abc v) v)
      (test-equal? "define and reference a function in qi space"
                   ((reference-qi abc) 5)
                   5))
    (let ()
      (define-for-qi (abc v . vs) v)
      (test-equal? "define and reference a function with rest args in qi space"
                   ((reference-qi abc) 5 6 7)
                   5)))
   (test-suite
    "define-qi-syntax"
    (let ()
      (define-qi-syntax abc (λ (_) #'add1))
      (test-equal? "define syntax in qi space"
                   ((☯ abc) 1)
                   2))
    (let ()
      (define-qi-syntax (abc _) #'add1)
      (test-equal? "define syntax in qi space, function form"
                   ((☯ abc) 1)
                   2)))
   (test-suite
    "define-qi-alias"
    (let ()
      (define-for-qi abc 5)
      (define-qi-alias pqr abc)
      (test-equal? "define an alias for a simple value binding in qi space"
                   (reference-qi pqr)
                   5))
    (let ()
      (define-for-qi (abc v) v)
      (define-qi-alias pqr abc)
      (test-equal? "define an alias for a function binding in qi space"
                   ((reference-qi pqr) 5)
                   5))
    (let ()
      (define-qi-alias my-amp amp)
      (test-equal? "define an alias for a Qi syntactic form"
                   ((☯ (~> (my-amp sqr) ▽)) 1 2 3)
                   (list 1 4 9))))))

(module+ main
  (void
   (run-tests tests)))
