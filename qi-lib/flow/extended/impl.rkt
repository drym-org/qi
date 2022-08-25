#lang racket/base

(provide ->boolean)

(define (->boolean v)
  (not (not v)))
