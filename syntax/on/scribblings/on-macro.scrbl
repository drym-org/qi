#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         pict/private/layout
         @for-label[syntax/on
                    racket]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
                 (make-evaluator 'racket/base
                                 '(require syntax/on))))

@title{Lisp's Missing Predicate Language}
@author{Siddhartha Kasivajhula}

@defmodule[syntax/on]

An embedded predicate language to allow convenient framing of programming logic in terms of predicates.

Every relation corresponds to a predicate, relations are the basis of logic, and logic is the soul of language. Predicates in a general sense are everywhere in human languages as well as in programming languages. They are essential in the way that we understand and express ideas, in the way that we think about and write programs. But in the absence of syntax that allows us to express ideas in terms of their @emph{subject-predicate} structure, such structure must be unraveled and expressed in terms of lower-level syntactic abstractions, abstractions which much be parsed by those reading the code into the higher level @emph{subject-predicate} structure you had in mind while writing it. This is an unnecessary toll on the conveyance of ideas, one that is eliminated by the present module.

@;{TODO:teaser examples}

@section{Syntax}

This section provides a specification of the basic syntax recognizable to all the predicate forms provided in this module.

@;{TODO: describe syntax - and, or, %, not, apply, with-key, .., and%, or%, ...}

@section{Forms}

The core form that defines and uses the predicate language is @racket[on], which can be used to describe arbitrary computations involving predicates, while another form, @racket[switch], leverages the former to provide a conditional dispatch form analogous to @racket[cond]. In addition, other forms like @racket[define-predicate] and @racket[define-switch] are provided that leverage these to create functions constrained to the predicate language -- for use in defining predicate functions, and dispatch functions, respectively. The advantage of using these forms over the usual general-purpose @racket[define] form is that constraints provide clarity, minimize redundancy, and provide guardrails against programmer error.

@defform*/subs[[(on (args) procedure-expr)
                (on (args)
                  (if [predicate consequent ...]
                      ...
                      [else consequent ...]))]
                ([args (code:line arg ...)]
                 [arg expr]
                 [predicate procedure-expr
                            (eq? value-expr)
                            (equal? value-expr)
                            (one-of? value-expr ...)
                            (= value-expr)
                            (< value-expr)
                            (> value-expr)
                            (<= value-expr)
                            (≤ value-expr)
                            (>= value-expr)
                            (≥ value-expr)
                            (all predicate)
                            (any predicate)
                            (none predicate)
                            (and predicate ...)
                            (or predicate ...)
                            (not predicate)
                            (and% predicate)
                            (or% predicate)
                            (with-key procedure-expr predicate)
                            (.. predicate ...)
                            (% predicate)
							(map predicate)
							(filter predicate)
							(foldl predicate value-expr)
							(foldr predicate value-expr)
                            (apply predicate)]
                 [consequent expr
                             (call call-expr)]
                 [call-expr procedure-expr
                            (.. call-expr ...)
                            (% call-expr)
							(map call-expr)
							(filter call-expr)
							(foldl call-expr value-expr)
							(foldr call-expr value-expr)
                            (apply call-expr)]
                 [procedure-expr (code:line any expression evaluating to a procedure)]
                 [value-expr (code:line any expression evaluating to a value)]
                 [expr (code:line any expression)]
                            )]{
  A form for defining predicates. Typically, @racket[on] should only be used for the general case of evaluating an expression in the context of a pre-defined subject (such as while defining a predicate). For the more specific case of predicate-based dispatch, use @racket[switch].

@examples[
    #:eval eval-for-docs
	(on (5) (and positive? odd?))
  ]
}

@defform[(switch (args ...)
           [predicate consequent ...]
           ...
           [else consequent ...])]{
  A predicate-based dispatch form, usable as an alternative to @racket[cond] and @racket[if].

@examples[
    #:eval eval-for-docs
	(switch (5)
	  [(and positive? odd?) 'yes]
	  [else 'no])
  ]
}

@deftogether[(
  @defform[(lambda/subject args body ...)]
  @defform[(predicate-lambda args body ...)]
  @defform[(lambdap args body ...)]
  @defform[(π args body ...)]
)]{
  Similiar to @racket[lambda] but constrained to the predicate language. This is exactly equivalent to @racket[(lambda args (on (args) body ...))]. @racket[predicate-lambda], @racket[lambdap] and @racket[π] are aliases for @racket[lambda/subject].
}

@deftogether[(
@defform[(switch-lambda (args ...)
           [predicate consequent ...]
           ...
           [else consequent ...])]
@defform[(λ01 (args ...)
           [predicate consequent ...]
           ...
           [else consequent ...])]
)]{
  Similar to @racket[lambda] but constrained to be a (predicate-based) dispatcher. This is exactly equivalent to @racket[(lambda args (switch (args) [predicate consequent ...] ... [else consequent ...]))]. @racket[λ01] is an alias for @racket[switch-lambda].

@examples[
    #:eval eval-for-docs
	((switch-lambda (x)
	   [(and positive? odd?) 'yes]
	   [else 'no]) 5)
  ]
}

@deftogether[(
  @defform[(define/subject (name args) body ...)]
  @defform[(define-predicate (name args) body ...)]
)]{
  Similiar to the function form of @racket[define] but constrained to the predicate language. This is exactly equivalent to @racket[(define name (lambda/subject args body ...))]. @racket[define-predicate] is an alias for @racket[define/subject].
}

@defform[(define-switch (args ...)
           [predicate consequent ...]
           ...
           [else consequent ...])]{
  Similiar to the function form of @racket[define] but constrained to be a (predicate-based) dispatcher. This is exactly equivalent to @racket[(define name (switch-lambda args [predicate consequent ...] ... [else consequent ...]))].
}
