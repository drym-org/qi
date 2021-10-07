#lang racket/base

(provide measure)

(require racket/list
         adjutor)

(define (measure fn . args)
  (second (values->list (time-apply fn args))))
