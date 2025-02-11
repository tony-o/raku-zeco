NAME
====

Zeco::Responses

SYNOPSIS
========

Contains typed responses for use in method chaining or serializing to JSON for web responses.

class Result 
-------------

    This class is used as a base for other messages and only intended for use
    when all members are provided or the defaults are appropriate. Inheriting
    classes may override the render mechanism, provide their own members, and
    provide other interfaces to assist in method chaining, testing, or provide
    other usability mechanisms.

    Members:
      Str  :message ()      - generic string message
      Bool :success (False) - indicates whether the message is a success message
      Int  :status  (500)   - response status
     
      method render(Response --> Nil)

      Signature: Response - hummingbird response object to serialize the class to

