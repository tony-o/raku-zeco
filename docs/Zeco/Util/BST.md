NAME
====

Zeco::Util::BST

SYNOPSIS
========

Binary index generator and reader for the type of search tree that this ecosystem software will generate.

sub index(IO() --> BST)
-----------------------

    Signature: IO - the path to a JSON file to create a BST from.
    Returns: BST - a binary index you can search or add things to.

    Returns a BST object you can call the methods documented below to find and
    search for modules in the index.

sub index-f(@meta --> BST)
--------------------------

    Signature: @meta - the dist information contained in the ecosystem's META.
    Returns: BST - a binary index you can search or add things to.

    Returns a BST object you can call the methods documented below to find and
    search for modules in the index.

class BST
---------

    Tree class containing ecosystem metadata info.  Most of the functions in this
    class are intentionally undocumented as they are used only internally and 
    subject to change/be not backwards compatible.  The methods documented below
    are intended to work regardless of other internal changes to this class.

### method find-partial(Str:D --> List)

    Signature: Str - searches the entire tree for a dist name containing
                     this Str.
    Returns: List - the list of matches.

### method find(Str:D --> List)

    Signature: Str - the module name to find.
    Returns: Associative|Nil - the META for the exact match or Nil if nothing was
                                found.

    Looks for an exact dist match to the given Str.

### method find-partial-index(IO(), Str:D --> List)

    Signature: IO - the path to the binary index to search
               Str - searches the entire tree for a dist name containing
                     this Str.
    Returns: List - the list of matches.

    Parses the index and runs find-partial(Str).

### method find-index(IO(), Str:D --> List)

    Signature: IO - the path to the binary index to search
               Str - the module name to find.
    Returns: Associative|Nil - the META for the exact match or Nil if nothing was
                                found.

    Parses the index and runs find(Str).

