#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         @for-label[qi
                    racket
                    (only-in relation
                             ->number
                             ->string
                             sum)]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
    (make-evaluator 'racket/base
                    '(require qi
                              (only-in racket/list range)
                              racket/string
                              relation)
                    '(define (sqr x)
                       (* x x)))))

@title{Introduction and Usage}

@section{What is a Flow?}

 A @deftech{flow} is either made up of flows, or is a native (e.g. Racket) function. Flows may be composed using a number of combinators that could yield either linear or nonlinear composite flows.

 A flow in general accepts @code{m} inputs and yields @code{n} outputs, for arbitrary non-negative integers @code{m} and @code{n}. We say that such a flow is @code{m × n}.

 The semantics of a flow is function invocation -- simply invoke a flow with inputs (i.e. ordinary arguments) to obtain the outputs.

 The Qi language allows you to describe and use flows in your code.

@section{Usage}

 Qi isn't specific to a domain (except the domain of functions!) and may be used in normal (e.g. Racket) code simply by employing an appropriate @seclink["Language_Interface"]{interface} form. Since some of the forms use and favor unicode characters (while also providing plain-English aliases), see @secref["Flowing_with_the_Flow"] for tips on entering these characters.

@examples[
    #:eval eval-for-docs
    ((☯ (~> sqr add1)) 3)
    (switch (2 3)
      [> -]
      [< +])
    (~> (3 4) (>< sqr) +)
  ]

@section{Motivating Examples}

@subsection{abs}

Let's say we want to implement @racket[abs]. This is a function that returns the absolute value of the input argument, i.e. the value unchanged if it is positive, and negated otherwise. With Racket, we might implement it like this:

@codeblock{
    (define (abs v)
      (if (negative? v)
          (- v)
          v))
}

For this very simple function, the input argument is mentioned @racket[4] times! An equivalent Qi definition is:

@codeblock{
    (define-switch abs-value
      [negative? -]
      [else _])
}

This uses the definition form of @racket[switch], which is a flow-oriented conditional form that is an alternative to @racket[if] and @racket[cond]. The @racket[_] symbol here indicates that the input is to be passed through unchanged, i.e. it is the trivial or identity flow. The input argument is not mentioned; rather, the definition expresses @racket[abs] as a conditioned transformation of the input.

More examples coming soon!

@section{Interoperating with the Host Language}

Arbitrary native (e.g. Racket) expressions can be used in flows in one of two ways. The first and most common way is to simply wrap the expression with a @racket[gen] form while within a flow context. This flow generates the @tech/reference{value} of the expression.

The second way is if you want to describe a flow using the native language instead of the flow language. In this case, use the @racket[esc] form. The wrapped expression in this case @emph{must} evaluate to a function, since functions are the only values describable in the native language that can be treated as flows. Note that use of @racket[esc] is unnecessary for function identifiers since these are usable as flows directly, and these can even be partially applied using standard application syntax, optionally with @racket[_] and @racket[__] to indicate argument placement. But you may still need it in the specific case where the identifier collides with a Qi form.

@section{Flowing with the Flow}

If your code flows but you don't, then we're only halfway there. This section will cover some UX considerations related to entering unicode characters that are used in the Qi forms, so that expressing flows in code is just a thought away.

The main thing is, you want to ensure that these forms have convenient keybindings:

@tabular[#:sep @hspace[1]
         (list (list @racket[☯])
               (list @racket[~>])
               (list @racket[-<])
               (list @racket[△])
               (list @racket[▽])
               (list @racket[⏚]))]

Now, it isn't just about being @emph{able} to enter them, but being able to enter them @emph{without effort}. This makes a difference, because having convenient keybindings for Qi is less about entering unicode conveniently than it is about @emph{expressing ideas} economically.

Some specific suggestions are included below for commonly-used editors.

@subsection{DrRacket}

Stephen De Gabrielle created a @seclink["top" #:doc '(lib "quickscript/scribblings/quickscript.scrbl")]{quickscript} for convenient entry of Qi forms, which you can find @hyperlink["https://gist.github.com/spdegabrielle/a6c1dc432599591bb7808c01ec04cfdb"]{here}. This option is based on using keyboard shortcuts to enter exactly the form you need.

Laurent Orseau's @other-doc['(lib "quickscript-extra/scribblings/quickscript-extra.scrbl")] library includes the @hyperlink["https://github.com/Metaxal/quickscript-extra/blob/master/scripts/complete-word.rkt"]{complete-word} script that allows you to define shorthands that expand into pre-written templates (e.g. @racket[(☯ \|)], with @racket[\|] indicating the cursor position), and includes some Qi templates with defaults that you could @seclink["Shadow_scripts" #:doc '(lib "quickscript/scribblings/quickscript.scrbl")]{customize further}. This option is based on short textual aliases with a common keyboard shortcut.

There are also a few general unicode entry options, including a quickscript for @hyperlink["https://gist.github.com/Metaxal/c328dca7849018388f792094f8e0895c"]{unicode entry in DrRacket}, and @hyperlink["https://docs.racket-lang.org/the-unicoder/index.html"]{The Unicoder} by William Hatch for system-wide unicode entry. While these options are useful and recommended, they are not a substitute for the Qi-specific options above but a complement to them.

Use any combination of the above that would help you express yourself economically and fluently.

@subsection{Vim/Emacs}

For Vim and Emacs Evil users, here are suggested keybindings for use in insert mode:

@tabular[#:sep @hspace[1]
         (list (list @bold{Form} @bold{Keybinding})
               (list @racket[☯] @code{C-;})
               (list @racket[~>] @code{C->})
               (list @racket[-<] @code{C-<})
               (list @racket[△] @code{C-v})
               (list @racket[▽] @code{C-V})
               (list @racket[⏚] @code{C-=}))]

For vanilla Emacs users, I don't have specific suggestions since usage patterns vary so widely. But you may want to define a custom @hyperlink["https://www.emacswiki.org/emacs/InputMethods"]{input method} for use with Qi (i.e. don't rely on the LaTeX input method, which is too general, and therefore isn't fast), or possibly use a @hyperlink["https://www.emacswiki.org/emacs/Hydra"]{Hydra}.

@section{Relationship to the Threading Macro}

Qi's threading form @racket[~>] is a more general version, and almost drop-in alternative, to the usual threading macro in @other-doc['(lib "scribblings/threading.scrbl")]. You might consider migrating to Qi if you need to thread more than one argument or would like to make more pervasive use of flow-oriented reasoning. To do so, the only difference is that the input arguments to Qi's threading form must be wrapped in parentheses. This is in order to be unambiguous since we can thread more than one argument. The threading library also provides numerous shorthands for common cases, many of which don't have equivalents in Qi -- if you'd like to have these, please create an issue on the source repo to register your interest.
