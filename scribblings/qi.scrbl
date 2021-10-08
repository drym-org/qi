#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         @for-label[qi
                    racket
                    (only-in relation ->number ->string sum)]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
    (make-evaluator 'racket/base
                    '(require qi
                              (only-in racket/list range)
                              relation)
                    '(define (sqr x)
                       (* x x)))))

@title{Qi: A Functional, Flow-Oriented DSL}
@author{Siddhartha Kasivajhula}

@defmodule[qi]

An embedded, general-purpose language to allow convenient framing of programming logic in terms of functional @emph{flows}.

One way to structure computations is as a flowchart, with arrows representing logical transitions where the next step need not have anything to do with the preceding one -- their sequence is all that's entailed in the arrow. This is the standard model we implicitly employ when writing functions in Racket or another programming language. The present module provides another way, where computations are structured as a flow like a flow of energy, electricity passing through a circuit, rivers flowing through channels. In this model, arrows represent that the outputs of one flow feed into another. This higher-level constraint allows us to compose simple functions to derive complex and robust functional pipelines with a minimum of repetition and boilerplate, engendering @hyperlink["https://www.theschooloflife.com/thebookoflife/wu-wei-doing-nothing/"]{effortless clarity}.

@examples[
    #:eval eval-for-docs
    ((☯ (and positive? odd?)) 5)
    ((☯ (<= 5 _ 10)) 6)
    ((☯ (<= 5 _ 10)) 12)
    ((☯ (~> (>< ->string) string-append)) 5 7)
    (define-switch (abs n)
      [negative? (* -1)]
      [else _])
    (abs -5)
    (abs 5)
    (define-flow (≈ m n)
      (~> - abs (< 1)))
    (≈ 5 7)
    (≈ 5 5.4)
    (define-flow (root-mean-square vs)
      (~>> (map sqr) (-< sum length) / sqrt))
    (root-mean-square (range 10))
  ]

@section{Introduction}

 A @deftech{flow} is either made up of flows, or is a native (e.g. Racket) function. Flows may be composed using a number of combinators that could yield either linear or nonlinear composite flows.

 The flow @racket[gen] allows an ordinary value to be "lifted" into a flow -- thus, any value can be incorporated into flows.

 The semantics of a flow is function invocation -- simply invoke a flow with inputs (i.e. ordinary arguments) to obtain the outputs. A flow in general is @code{n × m}, i.e. it accepts @code{n} inputs and yields @code{m} outputs, for arbitrary non-negative integers @code{m} and @code{n}.

@section{Syntax}

This section provides a specification of the basic syntax recognizable to all of the forms provided in this module.

@;{TODO: describe syntax - and, or, %, not, apply, with-key, .., and%, or%, ...}

@section{Forms}

The core form that defines and uses the flow language is @racket[☯], while other forms such as @racket[on], @racket[switch], and @racket[~>] leverage the former to provide convenient syntax in specialized cases. @racket[on] provides a way to declare the arguments to the flow up front. @racket[~>] is similar to @racket[on] but implicitly threads the arguments through a sequence of flows. @racket[switch] is a conditional dispatch form analogous to @racket[cond] whose predicate and consequent expressions are all flows. In addition, other forms like @racket[define-flow] and @racket[define-switch] are provided that leverage these to create functions constrained to the flow language, for use in defining predicates, dispatchers, or arbitrary transformations. The advantage of using these forms over the usual general-purpose @racket[define] form is that they are more clear and more robust, as the constraints they impose minimize boilerplate by narrowing scope, while also providing guardrails against programmer error.

@deftogether[(
@defform*/subs[[(☯ flow-expr)]
               ([flow-expr _
                           (one-of? flow-expr)
                           (all flow-expr)
                           (any flow-expr)
                           (none flow-expr)
                           (and flow-expr)
                           (or flow-expr)
                           (not flow-expr)
                           (gen flow-expr)
                           (NOT flow-expr)
                           (AND flow-expr)
                           (OR flow-expr)
                           (NOR flow-expr)
                           (NAND flow-expr)
                           (XOR flow-expr)
                           (XNOR flow-expr)
                           (and% flow-expr)
                           (or% flow-expr)
                           (~> flow-expr)
                           (thread flow-expr)
                           (~>> flow-expr)
                           (thread-right flow-expr)
                           (any? flow-expr)
                           (all? flow-expr)
                           (none? flow-expr)
                           (X flow-expr)
                           (crossover flow-expr)
                           (>< flow-expr)
                           (amp flow-expr)
                           (pass flow-expr)
                           (== flow-expr)
                           (relay flow-expr)
                           (-< flow-expr)
                           (tee flow-expr)
                           (select flow-expr)
                           (group flow-expr)
                           (sieve flow-expr)
                           (if flow-expr)
                           (switch flow-expr)
                           (gate flow-expr)
                           (ground flow-expr)
                           (fanout flow-expr)
                           (feedback flow-expr)
                           (inverter flow-expr)
                           (effect flow-expr)
                           (collect flow-expr)
                           (apply flow-expr)
                           (esc flow-expr)
                           (val:literal flow-expr)
                           (quote flow-expr)
                           ((__) flow-expr)
                           ((_) flow-expr)
                           (() flow-expr)
                           (ex flow-expr)
                           (_ flow-expr)
    ])]
  @defform[(flow ...)]
  )]{
  Define a @tech{flow}.

@examples[
    #:eval eval-for-docs
	((☯ (and positive? odd?)) 5)
  ]
}

@defform[(on (args ...) flow-expr)]{
  Define a @tech{flow} with the inputs named in advance.

  Typically, @racket[on] should only be used for the general case of evaluating an expression in the context of a pre-defined subject (such as while defining a predicate). For the more specific case of predicate-based dispatch, use @racket[switch].
@examples[
    #:eval eval-for-docs
	(on (5) (and positive? odd?))
  ]
}

@deftogether[(
@defform[(~> (args ...) flow-expr ...)]
@defform[(~>> (args ...) flow-expr ...)]
)]{
  Thread inputs through a sequence of flows. @racket[~>] threads arguments in the first position by default, while @racket[~>>] uses the last position, but in either case the positions can instead be explicitly indicated by using @racket[_].

  As flows themselves can be nonlinear, these threading forms too support arbitrary arity changes along the way to generating the result.

@examples[
    #:eval eval-for-docs
	(~> (3) sqr add1)
	(~> (3) (-< sqr add1) +)
	(~> ("a" "b") (string-append "c"))
	(~>> ("b" "c") (string-append "a"))
	(~> ("a" "b") (string-append _ "-" _))
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
	  [(and positive? odd?) (~> sqr add1)]
	  [else _])
	(switch (2 3)
	  [< +]
	  [else min])
  ]
}

@deftogether[(
  @defform[(flow-lambda args body ...)]
  @defform[(π args body ...)]
)]{
  Similiar to @racket[lambda] but constrained to the flow language. This is exactly equivalent to @racket[(lambda args (on (args) body ...))]. @racket[π] is an alias for @racket[flow-lambda].
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
	   [(and positive? odd?) (~> sqr add1)]
	   [else _]) 5)
  ]
}

@deftogether[(
  @defform[(define-flow (name args) body ...)]
)]{
  Similiar to the function form of @racket[define] but constrained to the flow language. This is exactly equivalent to @racket[(define name (lambda/subject args body ...))].
}

@defform[(define-switch (args ...)
           [predicate consequent ...]
           ...
           [else consequent ...])]{
  Similiar to the function form of @racket[define] but constrained to be a (predicate-based) dispatcher. This is exactly equivalent to @racket[(define name (switch-lambda args [predicate consequent ...] ... [else consequent ...]))].
}

@section{Usage}

The Qi language isn't specific to a domain (except the domain of functions!) and may be used in normal (e.g. Racket) code simply by employing the appropriate @seclink["Forms"]{form}.

Arbitrary native (e.g. Racket) expressions can be used in flows in one of two ways. The first and most common way is to simply wrap the expression with a @racket[gen] form while within a flow context. This flow generates the @tech/reference{value} of the expression. The second way is if you want to describe a flow using the native language instead of the flow language. In this case, use the @racket[esc] form. The wrapped expression in this case @emph{must} evaluate to a function, since functions are the only values describable in the native language that can be treated as flows. Note that use of @racket[esc] is unnecessary for functions designated by identifiers since these are usable as flows directly, but you may need it in the specific case where the identifier collides with a Qi form.
