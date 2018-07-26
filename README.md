# NodeStar

This project aims to better visualize the Stellar network and its quorum sets with the following:

* iOS App - NodeStar
* Math

Originally discussed [on Galactic Talk](https://galactictalk.org/d/1521-what-are-indicators-of-a-healthy-stellar-network/3)

## iOS App - NodeStar

It'll cost $0.99 from the App Store (coming soon) or download the source and install it with xcode.

We're creating an app that:

* parses information from [StellarBeat.io](https://stellarbeat.io/nodes/dataset) -- Thanks StellarBeat!
 * https://github.com/stellarbeat/js-stellar-node-connector
* displays interesting summary network & quorum set metrics
* display list of all validators
* graphically visualizes a nodes quorum set
* computes some metrics on quorum set nodes [below](#Math)

Eventually

* visualizes the network of all validators and their quorum sets
* computes some overall health metrics
* incorporates [Stellar White Paper concepts](https://www.stellar.org/papers/stellar-consensus-protocol.pdf) like Dispensable Sets

## Math

We're developing standard language and metrics for discussing the stellar network and specific quorum sets dependence on a specific node or set of nodes.

Terms:

* Effected - how often does node A have an effect on quorum set Q
* Effect() - fraction of node truthiness combinations where node A has an effect on quorum set Q
* Require() - fraction of node truthiness combinations where node A can veto, when Q otherwise would be true
* Influence() - fraction of node truthiness combinations where node A can overpower, when it Q otherwise would be false


### Part 1
![alt text](math/math1.png "Math 1")

### Part 2
![alt text](math/math2.png "Math 2")


