#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         @for-label[qi
                    racket
                    syntax/parse/define]]

@(define eval-for-docs
  (call-with-trusted-sandbox-configuration
   (lambda ()
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
    (make-evaluator 'racket/base
                    '(require qi
                              (only-in racket/list range)
                              racket/string)
                    '(define ->string number->string)
                    '(define (sqr x)
                       (* x x)))))))

@title{Language Interface}

The most common way to use Qi is via interface macros in a host language such as Racket. Qi may also be used in tandem with other embedded or hosted DSLs.

@table-of-contents[]

@section{Using Qi from the Host Language}

The core entry-point to Qi from the host language is the form @racket[☯]. In addition, other forms such as @racket[on], @racket[switch], and @racket[~>] build on top of @racket[☯] to provide convenient syntax in specialized cases. Together, these forms represent the interface between the host language (e.g. Racket) and Qi.

@subsection{Core}

@deftogether[(
@defform*/subs[[(☯ flow-expr)]
               ([flow-expr (code:line)
                           _
                           (gen expr ...)
                           △
                           sep
                           ▽
                           collect
                           (esc expr)
                           (clos flow-expr)
                           (one-of? expr ...)
                           (all flow-expr)
                           (any flow-expr)
                           (none flow-expr)
                           (and flow-expr ...)
                           (or flow-expr ...)
                           (not flow-expr)
                           (and% flow-expr ...)
                           (or% flow-expr ...)
                           NOT
                           !
                           AND
                           &
                           OR
                           ∥
                           NOR
                           NAND
                           XOR
                           XNOR
                           any?
                           all?
                           none?
                           inverter
                           ⏚
                           ground
                           (~> flow-expr ...)
                           (thread flow-expr ...)
                           (~>> flow-expr ...)
                           (thread-right flow-expr ...)
                           X
                           crossover
                           (== flow-expr ...)
                           (relay flow-expr ...)
                           (==* flow-expr ...)
                           (relay* flow-expr ...)
                           (-< flow-expr ...)
                           (tee flow-expr ...)
                           fanout
                           (fanout number)
                           feedback
                           (feedback number flow-expr)
                           (feedback number (then flow-expr) flow-expr)
                           (feedback (while flow-expr) flow-expr)
                           (feedback (while flow-expr) (then flow-expr) flow-expr)
                           count
                           1>
                           2>
                           3>
                           4>
                           5>
                           6>
                           7>
                           8>
                           9>
                           (select index ...)
                           (block index ...)
                           (bundle (index ...) flow-expr flow-expr)
                           (group number flow-expr flow-expr)
                           sieve
                           (sieve flow-expr flow-expr flow-expr)
                           (partition [flow-expr flow-expr] ...)
                           (if flow-expr flow-expr)
                           (if flow-expr flow-expr flow-expr)
                           (when flow-expr flow-expr)
                           (unless flow-expr flow-expr)
                           switch
                           (switch switch-expr ...)
                           (switch (% flow-expr) switch-expr ...)
                           (switch (divert flow-expr) switch-expr ...)
                           (gate flow-expr)
                           ><
                           (>< flow-expr)
                           amp
                           (amp flow-expr)
                           pass
                           (pass flow-expr)
                           <<
                           (<< flow-expr)
                           (<< flow-expr flow-expr)
                           >>
                           (>> flow-expr)
                           (>> flow-expr flow-expr)
                           (loop flow-expr)
                           (loop flow-expr flow-expr)
                           (loop flow-expr flow-expr flow-expr)
                           (loop flow-expr flow-expr flow-expr flow-expr)
                           (loop2 flow-expr flow-expr flow-expr)
                           (ε flow-expr flow-expr)
                           (effect flow-expr flow-expr)
                           apply
                           literal
                           (quote value)
                           (quasiquote value)
                           (quote-syntax value)
                           (syntax value)
                           (qi:* expr ...)
                           (expr expr ... __ expr ...)
                           (expr expr ... _ expr ...)
                           (expr expr ...)
                           expr]
                [expr a-racket-expression]
                [index exact-positive-integer?]
                [number exact-nonnegative-integer?]
                [switch-expr [flow-expr flow-expr]
                             [flow-expr (=> flow-expr)]
                             [else flow-expr]]
                [literal a-racket-literal]
                [value a-racket-value])]
  @defform[(flow flow-expr)]
  )]{
  Define a @tech{flow} by using the various @seclink["Qi_Forms"]{forms} of the Qi language.

This produces a value that is an ordinary function. When invoked with arguments, this function passes those arguments as inputs to the defined flow, producing its outputs as return values. A flow defined in this manner does not name its inputs, and like any function, it only produces output when it is invoked with inputs.

See also @racket[on] and @racket[~>], which are shorthands to invoke the flow with arguments immediately.

@examples[
    #:eval eval-for-docs
    ((☯ (* 5)) 3)
    ((☯ (and positive? odd?)) 5)
    ((☯ (~> + (* 2))) 3 5)
  ]
}

@defform[(on (arg ...) flow-expr)]{
  Define and execute a @tech{flow} with the inputs named in advance.

  This is a way to pass inputs to a flow that is an alternative to the usual function invocation syntax (i.e. an alternative to simply invoking the flow with arguments). It may be preferable in certain cases, since the inputs are named at the beginning rather than at the end.

  In the respect that it both defines as well as invokes the flow, it has the same relationship to @racket[☯] as @racket[let] has to @racket[lambda], and can be used in analogous ways.

  Equivalent to @racket[((☯ flow-expr) arg ...)].

@examples[
    #:eval eval-for-docs
    (on (5) (and positive? odd?))
    (on ((* 2 3) (+ 5 2))
      (~> (>< ->string)
          string-append))
  ]
}

@subsection{Threading}

@deftogether[(
@defform[(~> (args ...) flow-expr ...)]
@defform[(~>> (args ...) flow-expr ...)]
)]{
  These @emph{Racket} forms leverage the identically-named @emph{Qi} forms to thread inputs through a sequence of flows. @racket[~>] threads arguments in the first position by default, while @racket[~>>] uses the last position, but in either case the positions can instead be explicitly indicated by using @racket[_] or @racket[___].

  @margin-note{In these docs, we'll sometimes refer to the host language as "Racket" for convenience, but it should be understood that Qi may be used with any host language.}

  Note that, as there may be any number of input arguments, they must be wrapped in parentheses in order to distinguish them from the flow specification -- @seclink["Relationship_to_the_Threading_Macro"]{unlike the usual threading macro} where the input is simply the first argument.

  As flows themselves can be nonlinear, these threading forms too support arbitrary arity changes along the way to generating the result.

  In the respect that these both define as well as invoke the flow, they have the same relationship to @racket[☯] as @racket[let] has to @racket[lambda], and can be used in analogous ways.

  Equivalent to @racket[((☯ (~> flow-expr ...)) args ...)].

  See also: @secref["Relationship_to_the_Threading_Macro"].

@examples[
    #:eval eval-for-docs
    (~> (3) sqr add1)
    (~> (3) (-< sqr add1) +)
    (~> ("a" "b") (string-append "c"))
    (~>> ("b" "c") (string-append "a"))
    (~> ("a" "b") (string-append _ "-" _))
  ]
}

@subsection[#:tag "interface-conditionals"]{Conditionals}

@defform[(switch (arg ...)
           maybe-divert-clause
           [predicate consequent]
           ...
           [else consequent])]{
  A predicate-based dispatch form, usable as an alternative to @racket[cond], @racket[if], and @racket[match].

Each of the @racket[predicate] and @racket[consequent] expressions is a flow, and they are each typically invoked with @racket[arg ...], so that the arguments need not be mentioned anywhere in the body of the form.

 This @emph{Racket} form leverages the identically-named @emph{Qi} form. See @secref["Conditionals"] for its full syntax and behavior.

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

@subsection{Lambdas}

  These anonymous function forms may be used in cases where you need to explicitly @emph{name} the arguments for some reason. Otherwise, in most cases, just use @racket[☯] directly instead as it produces a function while avoiding the extraneous layer of bindings.

@deftogether[(
  @defform[(flow-lambda args flow-expr)]
  @defform[(flow-λ args flow-expr)]
  @defform[(π args flow-expr)]
)]{
  Similiar to @racket[lambda] but constrained to the flow language. This is exactly equivalent to @racket[(lambda args (on (args) flow-expr))] except that the keywords only introduce bindings, and aren't part of the values that are fed into @racket[flow-expr]. @racket[flow-λ] and @racket[π] are aliases for @racket[flow-lambda]. The present form mainly finds its use internally in @racket[define-flow], and in most cases you should use @racket[☯] directly.

@examples[
    #:eval eval-for-docs
    ((flow-lambda a* _) 1 2 3 4)
    ((flow-lambda (a b c d) list) 1 2 3 4)
    ((flow-lambda (a . a*) list) 1 2 3 4)
    ((flow-lambda (a #:b b . a*) list) 1 2 3 4 #:b 'any)
    ((flow-lambda (a #:b b c . a*) list) 1 2 3 4 #:b 'any)
    ((flow-lambda (a b #:c c) (~> + (* c))) 2 3 #:c 10)
  ]
}

@deftogether[(
  @defform[(switch-lambda args
             maybe-divert-clause
             [predicate consequent ...]
             ...
             [else consequent ...])]
  @defform[(switch-λ args
             maybe-divert-clause
             [predicate consequent ...]
             ...
             [else consequent ...])]
  @defform[(λ01 args
             maybe-divert-clause
             [predicate consequent ...]
             ...
             [else consequent ...])]
)]{
  Similar to @racket[lambda] but constrained to be a flow-based dispatcher. This is exactly equivalent to @racket[(lambda args (switch (args) maybe-divert-clause [predicate consequent ...] ... [else consequent ...]))] except that the keywords only introduce bindings, and aren't part of the values that are fed into @racket[flow-expr]. @racket[switch-λ] and @racket[λ01] are aliases for @racket[switch-lambda].

@examples[
    #:eval eval-for-docs
    ((switch-lambda (a #:b b . a*)
       [memq 'yes]
       [else 'no]) 2 2 3 4 #:b 'any)
    ((switch-lambda (a #:fx fx . a*)
       [memq (~> 1> fx)]
       [else 'no]) 2 2 3 4 #:fx number->string)
    ((switch-lambda (x)
       [(and positive? odd?) (~> sqr add1)]
       [else _]) 5)
  ]
}

@subsection{Definitions}

The following definition forms may be used in place of the usual general-purpose @racket[define] form when defining flows.

@deftogether[(
  @defform[(define-flow name flow-expr)]
  @defform[#:link-target? #f
           (define-flow (head args) flow-expr)])]{
  Similiar to the function form of @racket[define] but constrained to the flow language. This is exactly equivalent to @racket[(define head (flow-lambda args flow-expr))].
}

@deftogether[(
  @defform[(define-switch name
             maybe-divert-clause
             [predicate consequent ...]
             ...
             [else consequent ...])]
  @defform[#:link-target? #f
           (define-switch (head args)
             maybe-divert-clause
             [predicate consequent ...]
             ...
             [else consequent ...])])]{
  Similiar to the function form of @racket[define] but constrained to be a (predicate-based) dispatcher. This is exactly equivalent to @racket[(define head (switch-lambda args maybe-divert-clause [predicate consequent ...] ... [else consequent ...]))].

@examples[
    #:eval eval-for-docs
    (define-switch abs
      [negative? -]
      [else _])
    (map abs (list -1 2 -3 4 -5))
  ]
}

The advantage of using these over the general-purpose @racket[define] form is that, as they express the definition at the appropriate level of abstraction and with the attendant constraints for the type of flow, they can be more clear and more robust, minimizing boilerplate while providing guardrails against programmer error.

@section{Using the Host Language from Qi}

Arbitrary native (e.g. Racket) expressions can be used in flows in one of two core ways. This section describes these two ways and also discusses other considerations regarding use of the host language alongside Qi.

@subsection{Using Racket Values in Qi Flows}

The first and most common way is to simply wrap the expression with a @racket[gen] form while within a flow context. This flow generates the @tech/reference{value} of the expression.

@examples[
    #:eval eval-for-docs
    (define v 2)
    ((☯ (~> (gen (* 5 v) (* 3 v)) list)))
]

@subsection{Using Racket to Define Flows}

The second way is if you want to describe a flow using the host language instead of Qi. In this case, use the @racket[esc] form. The wrapped expression in this case @emph{must} evaluate to a function, since functions are the only values describable in the host language that can be treated as flows. Note that use of @racket[esc] is unnecessary for function identifiers since these are @seclink["Identifiers"]{usable as flows directly}, and these can even be @seclink["Templates_and_Partial_Application"]{partially applied using standard application syntax}, optionally with @racket[_] and @racket[___] to indicate argument placement. But you may still need @racket[esc] in the specific case where the identifier collides with a Qi form.

@examples[
    #:eval eval-for-docs
    (define-flow add-two
      (esc (λ (a b) (+ a b))))
    (~> (3 5) add-two)
  ]

Finally, note that the following case works:

@examples[
    #:eval eval-for-docs
    (define (get-flow v)
      (☯ (~> sqr (+ v))))
    (~> (5) (get-flow 3))
  ]

You might expect here that the expression @racket[(get-flow 3)] would be treated as a @seclink["Templates_and_Partial_Application"]{partial application template}, so that the value @racket[5] would be provided to it as @racket[(get-flow 5 3)], resulting in an error. The reason this isn't what happens is that the partial application behavior in Qi when no argument positions have been indicated is implemented using currying rather than as a template application, and Racket's @racket[curry] and @racket[curryr] functions happen to evaluate to a result immediately if the maximum expected arguments have been provided. Thus, in this case, the @racket[(get-flow 3)] expression is first evaluated to produce a resulting flow which then receives the value @racket[5].

So, function applications where all of the arguments are provided syntactically, and which produce functions as their result, may be used as if they were simple function identifiers, and @racket[esc] may be left out.

@subsection{Using Racket Macros as Flows}

Flows are expected to be @seclink["What_is_a_Flow_"]{functions}, and so you cannot naively use a macro as a flow. But there are many ways in which you can. If you'd just like to use such a macro in a one-off manner, see @secref["Converting_a_Macro_to_a_Flow"] for an ad hoc way to do this. But a simpler and more complete way in many cases is to first register the macro (or any number of such macros) using @racket[define-qi-foreign-syntaxes] prior to use.

@defform[(define-qi-foreign-syntaxes form ...)]{
  This form allows you to register "foreign macros" for use with Qi. These could be Racket macros, or the forms of another DSL. By simply registering such forms by name using this form, you can for the most part use them just as if they were functions, except that the catch-all template @racket[___] isn't supported for such macros.

@examples[
    #:eval eval-for-docs
    (define-syntax-rule (double-me x) (* 2 x))
    (define-syntax-rule (subtract-two x y) (- x y))
    (define-qi-foreign-syntaxes double-me subtract-two)
    (~> (5) (subtract-two 4) double-me)
    (~>> (5) (subtract-two 4) double-me)
    (~> (5 4) (subtract-two _ _) double-me)
  ]

By doing this, you can thread multiple values through such syntaxes in the same manner as functions. The catch-all template @racket[___] isn't supported though, since macros (unlike functions) require all the "arguments" to be supplied syntactically at compile time. So while any number of arguments may be supplied to such macros, it must be a @emph{specific} rather than an @emph{arbitrary} number of them, which may be indicated syntactically via @racket[_] to indicate individual expected arguments and their positions.

Note that for a foreign macro used in identifier form (such as @racket[double-me] in the example above), it assumes a @emph{single} argument. This is different from function identifiers where they receive as many values as may happen to be flowing at runtime. With macros, as we saw, we cannot provide them an arbitrary number of arguments. If more than one argument is anticipated, explicitly indicate them using a @racket[_] template.

Finally, as macros "registered" in this way result in the implicit creation of @seclink["Qi_Macros"]{Qi macros} corresponding to each foreign macro, if you'd like to use these forms from another module, you'll need to provide them just like any other Qi macro, i.e. via @racket[(provide (for-space qi ...))].
}

@section{Using Qi with Another DSL}

Qi may also be used in tandem with other DSLs in a few different ways -- either directly, if the DSL is implemented simply as functions without custom syntax, or via a one-to-one macro "bridge" between the two languages (if the interface between the languages is small), or potentially by implementing the DSL itself as a Qi dialect (if the languages interact extensively).

@subsection{Using Qi Directly}

If the forms of the DSL are callable, i.e. if they are functions, then you can just use Qi with them the same way as with any other function.

@subsection{Using a Macro Bridge}

See @secref["Converting_a_Macro_to_a_Flow"].

Using the macro bridge approach, you would need to write a corresponding Qi macro for every form of your DSL that interacts with Qi (or use @racket[define-qi-foreign-syntaxes] to do this for you). If this interface between the two languages is large enough, and their use together frequent enough, this approach too may prove cumbersome. In such cases, it may be best to implement the DSL itself as a @seclink["Qi_Dialect_Interop"]{dialect of Qi}.

@subsection[#:tag "Qi_Dialect_Interop"]{Writing a Qi Dialect}

The problem with the @seclink["Using_a_Macro_Bridge"]{macro bridge approach} is that all paths between the two languages must go through a level of indirection in the host language. That is, the only way for Qi and the other DSL to interact is via Racket as an everpresent intermediary.

To get around this, a final possibility to consider is to translate the DSL itself so that it's implemented in Qi rather than Racket. That is, instead of being specified using Racket macros via e.g. @racket[define-syntax-parse-rule] and @racket[define-syntax-parser], it would rather be defined using @racket[define-qi-syntax-rule] and @racket[define-qi-syntax-parser] so that the language expands to Qi rather than Racket (directly). This would allow your language to be used with Qi seamlessly since it would now be a dialect of Qi.

There are many kinds of languages that you could write in Qi. See @secref["Writing_Languages_in_Qi"] for a view into the possibilities here, and what may be right for your language.

@close-eval[eval-for-docs]
@(set! eval-for-docs #f)
