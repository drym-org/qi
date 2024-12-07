#lang racket/base

(provide deforested?
         range-deforested?
         filter-deforested?
         map-deforested?
         filter-map-deforested?
         take-deforested?
         foldl-deforested?
         foldr-deforested?
         length-deforested?
         empty?-deforested?
         list-ref-deforested?)

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

(define (range-deforested? exp)
  (string-contains? (format "~a" exp) "range->cstream"))

(define (filter-deforested? exp)
  (string-contains? (format "~a" exp) "filter-cstream"))

(define (map-deforested? exp)
  (string-contains? (format "~a" exp) "map-cstream"))

(define (filter-map-deforested? exp)
  (string-contains? (format "~a" exp) "filter-map-cstream"))

(define (take-deforested? exp)
  (string-contains? (format "~a" exp) "take-cstream"))

(define (foldl-deforested? exp)
  (string-contains? (format "~a" exp) "foldl-cstream"))

(define (foldr-deforested? exp)
  (string-contains? (format "~a" exp) "foldr-cstream"))

(define (length-deforested? exp)
  (string-contains? (format "~a" exp) "length-cstream"))

(define (empty?-deforested? exp)
  (string-contains? (format "~a" exp) "empty?-cstream"))

(define (list-ref-deforested? exp)
  (string-contains? (format "~a" exp) "list-ref-cstream"))
