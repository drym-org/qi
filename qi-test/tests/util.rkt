#lang racket/base

(provide tests)

(require qi/private/util
         rackunit
         rackunit/text-ui
         racket/function)

(define tests
  (test-suite
   "util tests"

   (test-suite
    "report-syntax-error"
    (check-exn exn:fail:syntax?
               (thunk (report-syntax-error #'(dummy 1 2 3)
                                           "blah: blah"
                                           "Use it"
                                           "like"
                                           "this"))))))

(module+ main
  (void (run-tests tests)))
