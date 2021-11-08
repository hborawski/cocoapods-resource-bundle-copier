# cocoapods-resource-bundle-copier

A CocoaPods plugin to copy resources into the resource bundle location from other Bazel targets

## Installation

    $ gem install cocoapods-resource-bundle-copier

## Usage
In your `podspec`:
```ruby
  s.subspec 'Subspec' do |spec|
    spec.resource_bundles = {
        # One of the following
        'Subspec' => 'Resources/*',
        'Subspec' => 'Resources/*.png',
        'Subspec' => 'Resources/some_specific_file.png',
    }
  end
```
In your `Podfile`:

```ruby
plugin 'cocoapods-resource-bundle-copier', {
  'bazelCommand' => './bazelisk', # optional, default is `bazel`
  'resource_map' => {
    "MyPod/Subspec" => {'target' => "//some/bazel/target/...", 'files' => ['some_file.extension', 'another_file.extension']}
  }
}
```
