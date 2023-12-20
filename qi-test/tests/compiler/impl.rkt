#lang racket/base

(provide tests)

(require qi/flow/core/impl
         rackunit
         rackunit/text-ui
         (only-in racket/function thunk))

(define tests
  (test-suite
   "Compiler implementation functions tests"
   ;; Most of these are tested implicitly via testing the Qi forms
   ;; that compile to them. But some nuances of the implementation
   ;; aren't hit by the unit tests, and it doesn't seem desirable
   ;; to expand the form unit tests to cover these corner cases
   ;; of the low-level implementation, so we test them more
   ;; comprehensively here as needed.

   (test-suite
    "arg"
    (test-equal? "first argument"
                 ((arg 1) 0 3)
                 0)
    (test-equal? "second argument"
                 ((arg 2) 0 3)
                 3)
    (test-equal? "third argument"
                 ((arg 3) 0 3 5)
                 5)
    (test-exn "argument index too low - 1-indexed"
              exn:fail?
              (thunk ((arg 0) 0 3)))
    (test-exn "argument index too high - 1"
              exn:fail?
              (thunk ((arg 1))))
    (test-exn "argument index too high - 2"
              exn:fail?
              (thunk ((arg 2))))
    (test-exn "argument index too high - 3"
              exn:fail?
              (thunk ((arg 3)))))))

(module+ main
  (void
   (run-tests tests)))
