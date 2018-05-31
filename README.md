# ProxyResolver

[![CI Status](https://img.shields.io/travis/rinold/ProxyResolver.svg?style=flat)](https://travis-ci.org/rinold/ProxyResolver)
[![Version](https://img.shields.io/cocoapods/v/ProxyResolver.svg?style=flat)](https://cocoapods.org/pods/ProxyResolver)
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
    case .success(let proxy):
      guard let proxy = proxy else {
        // no proxy required
      }
      // here you can establish connection to proxy or whatever you want
      // print ("For \(url) use \(proxy.host):\(proxy.port)")
    case .failure(let error):
      // Handle error
  }
}
```

## Features

#### Supported system configurations
- [x] Auto Proxy Discovery*
- [x] Automatic Proxy Configuration URL*
- [x] Web Proxy
- [x] Socks

> \*  due to ATS protection auto-configuration url should be HTTPS or have  \*.local or unresolvable globally domain with `NSAllowsLocalNetworking` key configured in plist. More info could be found in [NSAppTransportSecurity reference](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW33).


#### Other (TBD)
- Proxy with required password support

> `Proxy.credentials` will automatically access `Proxy` keychain to retrieve configured for proxy account and password. As it would require permission from user the credentials are retrieved lazily only when you try to get them.

## Requirements
- Swift: 4+
- macOS: 10.10+

## Installation

ProxyResolver is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ProxyResolver'
```

## Author

ProxyResolver was initially inspired by the Starscream proxy support merge request.

rinold, mihail.churbanov@gmail.com

## License

ProxyResolver is available under the MIT license. See the LICENSE file for more info.
