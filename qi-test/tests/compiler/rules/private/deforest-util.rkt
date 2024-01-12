#lang racket/base

(provide deforested?
         filter-deforested?
         car-deforested?)

;; Note: an alternative way to make these assertions could be to add logging
;; to compiler passes to trace what happens to a source expression, capturing
;; those logs in these tests and verifying that the logs indicate the expected
;; passes were performed. Such logs would also allow us to validate that
;; passes were performed in the expected order, at some point in the future
;; when we might have nonlinear ordering of passes. See the Qi meeting notes:
;; "Validly Verifying that We're Compiling Correctly"
(require racket/string)

(define (deforested? exp)
  (string-contains? (format "~a" exp) "cstream"))

(define (filter-deforested? exp)
  (string-contains? (format "~a" exp) "filter-cstream"))

(define (car-deforested? exp)
  (string-contains? (format "~a" exp) "car-cstream"))
