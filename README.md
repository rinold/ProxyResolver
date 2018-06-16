# ProxyResolver

[![CI Status](https://img.shields.io/travis/rinold/ProxyResolver.svg?style=flat)](https://travis-ci.org/rinold/ProxyResolver)
![Swift](https://img.shields.io/badge/swift-4.1-green.svg)
[![Version](https://img.shields.io/cocoapods/v/ProxyResolver.svg?style=flat)](https://cocoapods.org/pods/ProxyResolver)
![Carthage](https://img.shields.io/badge/carthage-+-orange.svg)
![Carthage](https://img.shields.io/badge/spm-+-orange.svg)
[![License](https://img.shields.io/cocoapods/l/ProxyResolver.svg?style=flat)](https://cocoapods.org/pods/ProxyResolver)
[![Platform](https://img.shields.io/cocoapods/p/ProxyResolver.svg?style=flat)](https://cocoapods.org/pods/ProxyResolver)

ProxyResolver allows simply resolve the actual proxy information from users
system configuration and could be used for setting up Stream-based connections,
for example for Web Sockets.

Usage example:

```swift
import ProxyResolver

let proxy = ProxyResolver()
let url = URL(string: "https://github.com")!
proxy.resolve(for: url) { result in
  switch result {
    case .direct:
      // Direct connection allowed - no proxy required
      break
    case .proxy(let proxy):
      // here you can establish connection to proxy or whatever you want
      // proxy.type - one of ProxyType enum: .http, .https or .socks
      // proxy.host - host name of proxy to use
      // proxy.port - port number
      break
    case .error(let error):
      // Handle error
      break
  }
}
```

## Features

#### Supported system configurations
- [x] Auto Proxy Discovery*
- [x] Automatic Proxy Configuration URL*
- [x] Web Proxy (HTTP)
- [x] Secure Web Proxy (HTTPS)
- [x] SOCKS Proxy
- [ ] ~~FTP Proxy~~
- [ ] ~~Streaming Proxy (RTSP)~~
- [ ] ~~Gopher Proxy~~

\*  due to ATS protection auto-configuration url should be HTTPS or have  \*.local or unresolvable globally domain, otherwise you will need to set the `NSAllowsLocalNetworking` key in plist. More info could be found in [NSAppTransportSecurity reference](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW33).


#### Other (TBD)
- [x] Proxy with required password support  

`Proxy.credentials` will automatically access `Proxy` keychain to retrieve configured for proxy account and password. As it would require permission from user the credentials are retrieved lazily only when you try to get them.

---

- [x] Configurable  

You can use custom proxy configuration provider instead of system one, or provide your own fetcher for downloading auto-configuration scripts instead of default one based on NSURLSession.

---

- [x] Aligned with Apple recommendations

> "In general, you should try to download a URL using the first proxy in the array, try the second proxy if the first one fails, and so on." - as described in documentation for used  [CFNetworkCopyProxiesForURL](https://developer.apple.com/documentation/cfnetwork/1426639-cfnetworkcopyproxiesforurl) method.

Using the `ProxyResolverDelegate` you can try connection to resolved proxy and in case of any issue or if your just want to retrieve all - continue resolution if any proxy configuration are still available.

```swift
class CustomDelegate: ProxyResolverDelegate {
  func proxyResolver(_ proxyResolver: ProxyResolver, didResolve result: ProxyResolutionResult, for url: URL, resolveNext: ResolveNextRoutine?) {
    switch result {
    case .direct:
      // no proxy required - try to connect to your 'url' directly
      break
    case .proxy(let proxy):
      // try connect to your 'url' using resolved 'proxy'
      yourConnectMethod(to: url, using: proxy) { (response, error) in
        if let error = error {
          // If connection failed we will try to resolve next proxy if
          // available and retry connection
          resolveNext?()
        }
      }
    case .error(let error):
      // handle error
      break
    }
}
```
---
- [ ] Documentation

TBD

## Requirements
- Swift: 4+
- macOS: 10.10+

## Installation

ProxyResolver is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ProxyResolver'
```

Using [Carthage]() add following line to your Cartfile:

```ruby
GitHub "rinold/ProxyResolver"
```

## Author

ProxyResolver was initially inspired by the Starscream proxy support merge request.

rinold, mihail.churbanov@gmail.com

## License

ProxyResolver is available under the MIT license. See the LICENSE file for more info.
