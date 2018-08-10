# NodeStar

This project aims to better visualize the Stellar network and its quorum sets. It includes:

* [iOS App - NodeStar](#ios-app---nodestar)
* [Math](#math)

Originally discussed [on Galactic Talk](https://galactictalk.org/d/1521-what-are-indicators-of-a-healthy-stellar-network/7)

<hr/>

## iOS App - NodeStar

It'll cost $0.99 from the App Store (coming soon) or build from source and install it with xcode for free!

We're creating an app that:

* parses information from [StellarBeat.io raw data](https://stellarbeat.io/nodes/dataset) -- Thanks StellarBeat!
  * [StellarBeat.io source](https://github.com/stellarbeat/js-stellar-node-connector)
  * eventually get the data ourselves
* displays interesting summary network & quorum set metrics
* displays list of all validators
* graphically visualizes a nodes quorum set
* computes some metrics on quorum set nodes - [see math below](#math)

Eventually:

* visualizes the network of all validators and their quorum sets
* computes some overall health metrics
* incorporates [Stellar White Paper concepts](https://www.stellar.org/papers/stellar-consensus-protocol.pdf) like Dispensable Sets

<p float="left">
  <img src="iOS/screen-shots/3-quorum-set-depth-3.png" width="200" alt="NodeStar - Quorum Set Depth 3" />
  <img src="iOS/screen-shots/7-quorum-metrics.png" width="200" alt="NodeStar - Quorum Metrics" />
  <img src="iOS/screen-shots/6-math.png" width="200" alt="NodeStar - Math" />
</p>
<p float="left">
  <img src="iOS/screen-shots/4-summary-1.png" width="200" alt="NodeStar - Node Count Histogram" />
  <img src="iOS/screen-shots/5-summary-2.png" width="200" alt="NodeStar - Depth Histogram" />
  <img src="iOS/screen-shots/1-validators.png" width="200" alt="NodeStar - Stellar Validators Screenshot" />
</p>

### Install From Source
* clone repo
* `cd NodeStar/iOS/`
* `pod update`
* `open NodeStar.xcworkspace` or open with finder
* run from xcode

<hr/>

## Math

We're developing standard language and metrics for discussing the stellar network and specific quorum sets dependence on a specific node or set of nodes.

Terms:

* **Effected** - count of combinations where the selected node impacts the quorum result
* **Affect** - how often the selected node has an impact on the quorum result
* **Require** - how often the selected node is required to be true for quorum truths
* **Influence** - how often the selected node influences the quorum result to true where it otherwise would have been false


### Part 1 - Quorum Impact Metrics
![alt text](math/math1.tex.png "Math 1 - impact metrics")

### Part 2 - Simple Quorum
![alt text](math/math2.tex.png "Math 2 - simple quorum")

### Part 3 - Recursive Quorum
![alt text](math/math3.tex.png "Math 2 - recursive quorum")


