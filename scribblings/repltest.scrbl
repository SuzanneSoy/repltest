#lang scribble/manual
@require[@for-label[repltest
                    racket/base]]

@title{REPL test: copy-paste REPL interactions to define tests}
@author{georges}

@defmodule[repltest]

This package define a meta-language which parses a REPL
trace, and re-evaluates it, checking that the outputs
haven't changed.

This allows to quickly write preliminary unit tests based on
a debugging session. It is obviously not a substitute for
writing real tests, and these tests are more prone to the
“copy-pasted bogus output into the tests” problem.
