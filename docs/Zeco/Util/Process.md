NAME
====

Zeco::Util::Process

SYNOPSIS
========

This is a convenience wrapper around Proc::Async.

method proc(*@ --> List[$exit-code, $stdout, $stderr])
------------------------------------------------------

    Signature: *@ - all of the arguments to pass to Proc::Async.new.
    Returns: List[$exit-code, $stdout, $stderr]

    Convenience method to run Proc::Async and capture the program's output, any
    errors, and the exit-code of the process.

