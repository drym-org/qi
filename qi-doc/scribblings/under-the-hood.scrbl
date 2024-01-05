#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         scribble-math
         @for-label[qi
                    racket]]

@title{Under the Hood}

 As a language in the Racket ecosystem, Qi follows some of the same architectural principles as Racket itself. In particular, it has its own expander that expands Qi surface syntax to a smaller core language, and it also includes an optimizing compiler that operates on this generated core Qi syntax to produce optimized Racket code (which then goes through the similar and familiar process of @emph{Racket} expansion and compilation).

 They say that a compiler reveals the soul of a language. So in this section, we'll pull back the veil and gaze upon the soul of Qi, discussing details of the expander and compiler, what kinds of optimizations the compiler performs, what theories guide such optimizations, and how these theories affect the code you write.

@table-of-contents[]

@section{The Expander}

TODO: Qi macros and Core Qi. Many Qi forms are actually macros expanding to core forms, just as many Racket forms are macros (like cond). Bindings are scoped to the outermost @racket[~>].

@section{The Compiler}

TODO: Overview of compiler passes including deforestation. Theory of optimization: no accidental side effects, assumption of purity. Summary of and link to performance reports.
