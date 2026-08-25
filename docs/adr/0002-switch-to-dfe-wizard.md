# 1. Record architecture decisions

Date: 2026-08-25

## Status

Accepted

## Context

[NPQ-3460](https://dfedigital.atlassian.net/browse/NPQ-3460).

We have our own basic implementation of a wizard at present. This implements both forward and backward pointers into every step and can be hard to ensure forward and backward links work consistently and wizard routing is a frequent source of bugs.

There is now a generic wizard implementation available within DfE which uses a graph pattern to model linking steps, avoiding the 'double linked lists' pattern our wizard implements.

The DfE wizard has generic interfaces for areas of functionality such as storage of wizard data. This will allow us to store the users wizard data in the database instead of the users session, which will make it easier for us to debug issues with the users wizard journeys in production.

## Decision

We will port our wizard to the DfE-Digital/dfe-wizard gem and rewrite the routing logic using the graph structure it adds in the v1.0.0 release.

## Consequences

We will need to port our wizard over to the gem's implementation and add sufficient compatibility that we are able to run our test suite against both new and old implementations during the porting process.
