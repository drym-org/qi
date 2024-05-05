#lang racket/base

;; Upon instantiation of the module it define-and-register-pass for
;; deforestation
(require racket/list
         "flow/core/passes/pass-0100-deforest.rkt")

(provide (all-from-out racket/list))
