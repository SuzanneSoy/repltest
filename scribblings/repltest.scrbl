#lang scribble/manual
@require[@for-label[repltest
                    racket/base]
         scriblib/footnote]

@title{REPL test: copy-paste REPL interactions to define tests}
@author{Georges Dupéron}

Source code: @url{https://github.com/jsmaniac/repltest}

@defmodulelang[repltest]{
 The @racketmodname[repltest] language is a meta-language
 that replays a copy-pasted transcript of an interactive
 REPL (@racket[read-eval-print-loop]) session, checking that the
 outputs have not changed.
 
 This allows to quickly write preliminary unit tests based
 on a debugging session. It is however not a substitute for
 writing real tests, and these tests are more prone to the
 “copy-pasted bogus output into the tests” problem.}

@racketblock[
 @#,hash-lang[] @#,racketmodname[repltest] @#,racketmodname[racket]
 (define x 3)
 @#,racketid[>] (+ x 1)
 @#,racketresultfont{4}
 ]

The first part of the file is kept inside the top-level
module. This module uses the language indicated just after 
@racket[@#,hash-lang[] @#,racketmodname[repltest]], for
example:

@racketblock[
 @#,hash-lang[] @#,racketmodname[repltest] @#,racketmodname[typed/racket]]

After the first occurrence of the prompt (by default 
@racket["> "], later versions of this package will allow
customizing this) is encountered, all the remaining contents
of the file are understood as a REPL transcript. The prompt
is only recognized if it is outside of any s-expression,
which means that the @racket[>] function can be used
normally.

@racketblock[
 @#,hash-lang[] @#,racketmodname[repltest] @#,racketmodname[racket]
 (define x (> 3 4))
 @#,racketid[>] x
 @#,racketresultfont{#f}
 ]

@section{The @racketid[test] submodule}

This language injects a @racketid[test] submodule
using @racket[module*]. When the @racketid[test] module
is run, the expression after each prompt is read and
evaluated as if it had been typed inside a real REPL, using
@racket[read-eval-print-loop]. The result, as printed on the
standard output and standard error, is compared with the
text read until the next prompt. The next prompt will only
be recognized if it is not part of an s-expression, which
means that occurrences of @racket[>] inside an expression in
the output are correctly handled:

@racketblock[
 @#,hash-lang[] @#,racketmodname[repltest] @#,racketmodname[racket]
 (define x '(> 3 4))
 @#,racketid[>] x
 @#,racketresultfont{'(> 3 4)}
 @#,racketid[>] '(> 5 6)
 @#,racketresultfont{'(> 5 6)}
 ]

The fact that a real REPL is used means that any
language-specific output will be produced as expected. For
example @racketmodname[typed/racket] prints the type of the
result before the result itself, so it must be included in
the expected output:

@racketblock[
 @#,hash-lang[] @#,racketmodname[repltest] @#,racketmodname[typed/racket]
 (define x 0)
 @#,racketid[>] x
 @#,racketresultfont{0}
 ]

@section{Warning concerning comments}

Comments are not currently supported inside the REPL
transcript. Also, the current version does not the first
prompt being preceded by a comment.

@section{Warning concerning spaces and newlines}

The tests are space-sensitive, so care should be taken to
include a newline at the end of the file. This is due to
the fact that in most languages, the REPL prints a newline
after the result. Furthermore, extra spacing like blank
lines should not be added in the transcript part of the
file.

@section{Future improvements}

Later versions of this package will allow customizing the following aspects:

@itemlist[
 @item{Flexibility of whitespace comparisons (strip leading
  and trailing whitespace, or ignore all whitespace
  differences).}
 @item{Support comments before and inside the REPL
  transcript.}
 @item{Specifying a regexp matching the prompt, and a
  regexp for characters preceding the prompt which are not
  part of it (and therefore will be part of the preceding
  result or main module's code).}
 @item{Disable calling @racket[read] on the output
  expressions, which can be useful when the output contains
  unbalanced parenthesis, or do not otherwise match the
  language's syntax, for example:
  
  @; TODO: include this in the tests
  @racketblock[
 @#,hash-lang[] @#,racketmodname[repltest] @#,racketmodname[racket]
 @#,racketid[>] (displayln "(unbalanced")
 @#,racketresultfont{(unbalanced}
 @#,racketid[>] (displayln "#invalid (syntax . too . many . dots)")
 @#,racketresultfont{#invalid (syntax . too . many . dots)}]
  
  This will also have the side-effect of allowing the prompt
  to be matched inside s-expressions.}
 @item{Distinguish standard output (purple font in DrRacket),
  printed result (blue font) and standard error (red font).}]