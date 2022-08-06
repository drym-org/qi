#lang racket/base

(provide report-syntax-error
         define-alias)

(require racket/string
         racket/format
         syntax/parse/define
         (for-syntax racket/base))

(define (report-syntax-error name args usage . msgs)
  (raise-syntax-error name
                      (~a "Syntax error in "
                          (list* name args)
                          "\n"
                          "Usage:\n"
                          "  " usage
                          (if (null? msgs)
                              ""
                              (string-append "\n"
                                             (string-join msgs "\n"))))))

(define-syntax-parse-rule (define-alias alias:id name:id)
  (define-syntax alias (make-rename-transformer #'name)))
