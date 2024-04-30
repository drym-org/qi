#lang racket/base

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Special syntax for templates

;; These bindings are used for ~literal matching to introduce implicit
;; producer/consumer when none is explicitly given in the flow.
(provide cstream->list list->cstream)
(define cstream->list #'-cstream->list)
(define list->cstream #'-list->cstream)
