#lang racket/base

(provide ->boolean)

(define (->boolean v) (and v #t))
