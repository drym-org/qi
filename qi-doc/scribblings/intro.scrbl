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

@table-of-contents[]

@section{Overview}

Intro. Test.

One way to structure computations -- the one we typically employ when writing functions in Racket or another programming language -- is as a flowchart, with arrows representing transitions of control, indicating the sequence in which actions are performed. Aside from the implied ordering, the actions are independent of one another and could be anything at all. Another way -- provided by the present module -- is to structure computations as a fluid flow, like a flow of energy, electricity passing through a circuit, streams flowing around rocks. Here, arrows represent that actions feed into one another.

The former way is often necessary when writing functions at a low level, where the devil is in the details. But once these functional building blocks are available, the latter model is often more appropriate, allowing us to compose functions at a high level to derive complex and robust functional pipelines from simple components with a minimum of repetition and boilerplate, engendering @hyperlink["https://www.theschooloflife.com/thebookoflife/wu-wei-doing-nothing/"]{effortless clarity}. The facilities in the present module allow you to employ this flow-oriented model in any source program.

@examples[
    #:eval eval-for-docs
    #:label #f
    ((☯ (~> sqr add1)) 3)
    (map (☯ (~> sqr add1)) (list 1 2 3 4))
    (filter (☯ (< 5 _ 10)) (list 3 7 9 12))
    (~> (2 3) (>< ->string) string-append)
    (define-flow (≈ m n)
      (~> - abs (< 1)))
    (≈ 5 7)
    (≈ 5 5.4)
    (define-flow root-mean-square
      (~>> (map sqr) (-< sum length) / sqrt))
    (root-mean-square (range 10))
  ]

@section{What is a Flow?}

 A @deftech{flow} is either made up of flows, or is a native (e.g. Racket) function. Flows may be composed using a number of combinators that could yield either linear or nonlinear composite flows.

 A flow in general accepts @code{m} inputs and yields @code{n} outputs, for arbitrary non-negative integers @code{m} and @code{n}. We say that such a flow is @code{m × n}.

 The semantics of a flow is function invocation -- simply invoke a flow with inputs (i.e. ordinary arguments) to obtain the outputs.

 The Qi language allows you to describe and use flows in your code.

@section{Usage}

 Qi may be used in normal (e.g. Racket) code simply by employing an appropriate @seclink["Language_Interface"]{interface} form. These forms embed the Qi language into the host language, that is, they allow you to use Qi anywhere in your program and provide shorthands for common cases.

 Since some of the forms use and favor unicode characters (while also providing plain-English aliases), see @secref["Flowing_with_the_Flow"] for tips on entering these characters. Otherwise, if you're all set, head on over to the @seclink["Tutorial"]{tutorial}.

@examples[
    #:eval eval-for-docs
    ((☯ (~> sqr add1)) 3)
    (switch (2 3)
      [> -]
      [< +])
    (~> (3 4) (>< sqr) +)
  ]

@section{Flowing with the Flow}

If your code flows but you don't, then we're only halfway there. This section will cover some UX considerations related to programming in Qi, so that expressing flows in code is just a thought away.

The main thing is, you want to ensure that these forms have convenient keybindings:

@tabular[#:sep @hspace[1]
         (list (list @racket[☯])
               (list @racket[~>])
               (list @racket[-<])
               (list @racket[△])
               (list @racket[▽])
               (list @racket[⏚]))]

Now, it isn't just about being @emph{able} to enter them, but being able to enter them @emph{without effort}. This makes a difference, because having convenient keybindings for Qi is less about entering unicode conveniently than it is about @emph{expressing ideas} economically, just as having evocative symbols in Qi is less about brevity and more about appealing to the intuition. After all, as the old writer's adage goes, "show, don't tell."

Some specific suggestions are included below for commonly used editors.

@subsection{DrRacket}

Stephen De Gabrielle created a @seclink["top" #:doc '(lib "quickscript/scribblings/quickscript.scrbl")]{quickscript} for convenient entry of Qi forms: @other-doc['(lib "qi-quickscripts/scribblings/qi-quickscripts.scrbl")]. This option is based on using keyboard shortcuts to enter exactly the form you need.

Laurent Orseau's @other-doc['(lib "quickscript-extra/scribblings/quickscript-extra.scrbl")] library includes the @hyperlink["https://github.com/Metaxal/quickscript-extra/blob/master/scripts/complete-word.rkt"]{complete-word} script that allows you to define shorthands that expand into pre-written templates (e.g. @racket[(☯ \|)], with @racket[\|] indicating the cursor position), and includes some Qi templates with defaults that you could @seclink["Shadow_scripts" #:doc '(lib "quickscript/scribblings/quickscript.scrbl")]{customize further}. This option is based on short textual aliases with a common keyboard shortcut.

There are also a few general unicode entry options, including a quickscript for @hyperlink["https://gist.github.com/Metaxal/c328dca7849018388f792094f8e0895c"]{unicode entry in DrRacket}, and @hyperlink["https://docs.racket-lang.org/the-unicoder/index.html"]{The Unicoder} by William Hatch for system-wide unicode entry. While these options are useful and recommended, they are not a substitute for the Qi-specific options above but a complement to them.

Use any combination of the above that would help you express yourself economically and fluently.

@subsection{Vim/Emacs}

@subsubsection{Keybindings}

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

@subsubsection{Indentation}

In Racket Mode for Emacs, use the following config to indent Qi forms correctly:

@codeblock{
    (put 'switch 'racket-indent-function 1)
    (put 'switch-lambda 'racket-indent-function 1)
    (put 'on 'racket-indent-function 1)
    (put 'π 'racket-indent-function 1)
}

@section{Relationship to the Threading Macro}

The usual threading macro in @other-doc['(lib "scribblings/threading.scrbl")] is a purely syntactic transformation that does not make any assumptions about the expressions being threaded through, so that it works out of the box for threading values through both functions as well as macros. On the other hand, Qi is primarily oriented around @emph{functions}, and flows are expected to be @seclink["What_is_a_Flow_"]{function-valued}. Threading values through macros using Qi requires special handling.

In the most common case where you are threading functions, Qi's threading form @racket[~>] is a more general version, and almost drop-in alternative, to the usual threading macro. You might consider migrating to Qi if you need to thread more than one argument or would like to make more pervasive use of flow-oriented reasoning. To do so, the only change that would be needed is to wrap the input argument in parentheses. This is necessary in order to be unambiguous since Qi's threading form can thread more than one argument.

For macros, we cannot use them naively as flows because macros expect all of their "arguments" to be provided syntactically at compile time -- meaning that the number of arguments must be known at compile time. This is not in general possible with Qi since flows may consume and produce an arbitrary number of values, and this number is only determined at runtime. Depending on what you are trying to do, however, there are many ways in which you still can @seclink["Converting_a_Macro_to_a_Flow"]{treat macros as flows in Qi} -- from simple escapes into Racket to more structured approaches including @seclink["Qi_Dialect_Interop"]{writing a Qi dialect}.

The threading library also provides numerous shorthands for common cases, many of which don't have equivalents in Qi -- if you'd like to have these, please @hyperlink["https://github.com/countvajhula/qi/issues/"]{create an issue} on the source repo to register your interest.
