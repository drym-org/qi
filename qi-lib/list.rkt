#lang racket/base

;; Upon instantiation of the module it define-and-register-pass for
;; deforestation
(require "flow/core/compiler/0100-deforest.rkt"
         "flow/core/compiler/deforest/binding.rkt")

(provide (all-from-out "flow/core/compiler/deforest/binding.rkt"))
